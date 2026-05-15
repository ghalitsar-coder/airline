package com.skylink.airline.service;

import com.skylink.airline.dto.CalculateRequest;
import com.skylink.airline.dto.CalculateResult;
import com.skylink.airline.dto.CalculateResult.TaxLine;
import com.skylink.airline.dto.CalendarDayPrice;
import com.skylink.airline.dto.CreatePromotionRequest;
import com.skylink.airline.dto.FlightPriceDto;
import com.skylink.airline.dto.PromotionDto;
import com.skylink.airline.entity.FlightPrice;
import com.skylink.airline.entity.Promotion;
import com.skylink.airline.entity.TaxConfiguration;
import com.skylink.airline.exception.PricingException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class PricingService {

    private static final BigDecimal HUNDRED = new BigDecimal("100");

    public List<FlightPriceDto> searchPrices(String origin, String destination, String date) {
        // MVP: origin/destination/date filters are stubs; return all active prices.
        return FlightPrice.findAllActive().stream().map(FlightPriceDto::from).toList();
    }

    public List<FlightPriceDto> getPricesByFlight(UUID flightId) {
        List<FlightPrice> prices = FlightPrice.findByFlightId(flightId);
        if (prices.isEmpty()) {
            throw PricingException.notFound("FLIGHT_PRICES_NOT_FOUND", "No prices found for flight");
        }
        return prices.stream().map(FlightPriceDto::from).toList();
    }

    public CalculateResult calculate(CalculateRequest request) {
        if (request.flightId() == null || request.seatClass() == null || request.seatClass().isBlank()) {
            throw PricingException.badRequest("INVALID_REQUEST", "flight_id and seat_class are required");
        }

        FlightPrice price = FlightPrice.findBestForFlightAndClass(request.flightId(), request.seatClass());
        if (price == null) {
            throw PricingException.notFound("FLIGHT_PRICE_NOT_FOUND", "No price found for flight");
        }

        BigDecimal multiplier = classMultiplier(request.seatClass());
        BigDecimal baseFare = price.basePrice;
        BigDecimal subtotal = baseFare.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);

        List<TaxConfiguration> activeTaxes = TaxConfiguration.findActive();
        List<TaxLine> taxBreakdown = new ArrayList<>();
        BigDecimal taxTotal = BigDecimal.ZERO;
        for (TaxConfiguration tax : activeTaxes) {
            BigDecimal amount =
                    subtotal.multiply(tax.taxPercentage).divide(HUNDRED, 2, RoundingMode.HALF_UP);
            taxBreakdown.add(new TaxLine(tax.taxName, tax.taxPercentage, amount));
            taxTotal = taxTotal.add(amount);
        }

        BigDecimal discount = BigDecimal.ZERO;
        String appliedPromo = null;
        if (request.promoCode() != null && !request.promoCode().isBlank()) {
            Promotion promo = Promotion.findActiveByCode(request.promoCode());
            if (promo == null) {
                throw PricingException.unprocessable("PROMO_INVALID", "Promotion code is not valid or expired");
            }
            appliedPromo = promo.promoCode;
            discount = applyDiscount(promo, subtotal.add(taxTotal));
        }

        BigDecimal totalPerPassenger = subtotal.add(taxTotal).subtract(discount).max(BigDecimal.ZERO);
        int passengers = request.effectivePassengerCount();
        BigDecimal grandTotal = totalPerPassenger.multiply(BigDecimal.valueOf(passengers));

        return new CalculateResult(
                request.flightId(),
                normalizeSeatClass(request.seatClass()),
                baseFare,
                multiplier,
                subtotal,
                taxBreakdown,
                taxTotal,
                appliedPromo,
                discount,
                totalPerPassenger,
                passengers,
                grandTotal,
                price.currencyCode != null ? price.currencyCode.trim() : "IDR");
    }

    public List<PromotionDto> listActivePromotions() {
        return Promotion.findActive().stream().map(PromotionDto::from).toList();
    }

    @Transactional
    public PromotionDto createPromotion(CreatePromotionRequest request) {
        validatePromotionRequest(request);

        if (Promotion.find("upper(promoCode) = ?1", request.promoCode().toUpperCase()).firstResult()
                != null) {
            throw PricingException.conflict("PROMO_EXISTS", "Promotion code already exists");
        }

        Promotion promotion = new Promotion();
        promotion.promotionId = UUID.randomUUID();
        promotion.promoCode = request.promoCode().toUpperCase(Locale.ROOT);
        promotion.discountType = request.discountType().toUpperCase(Locale.ROOT);
        promotion.discountValue = request.discountValue();
        promotion.validFrom = request.validFrom();
        promotion.validUntil = request.validUntil();
        promotion.isActive = request.isActive() == null || request.isActive();
        promotion.persist();

        return PromotionDto.from(promotion);
    }

    public List<CalendarDayPrice> calendarPrices(String routeId, String month) {
        // MVP stub: lowest base_price per calendar day from flight_prices.valid_from.
        YearMonth yearMonth = parseMonth(month);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end = yearMonth.atEndOfMonth();

        Map<LocalDate, CalendarDayPrice> byDay = new LinkedHashMap<>();
        for (FlightPrice price : FlightPrice.findAllActive()) {
            LocalDate day = price.validFrom.atZone(ZoneOffset.UTC).toLocalDate();
            if (day.isBefore(start) || day.isAfter(end)) {
                continue;
            }
            String currency = price.currencyCode != null ? price.currencyCode.trim() : "IDR";
            byDay.compute(
                    day,
                    (d, existing) -> {
                        if (existing == null || price.basePrice.compareTo(existing.lowestBasePrice()) < 0) {
                            return new CalendarDayPrice(d, price.basePrice, currency);
                        }
                        return existing;
                    });
        }

        return byDay.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(Map.Entry::getValue)
                .toList();
    }

    public static BigDecimal classMultiplier(String seatClass) {
        return switch (normalizeSeatClass(seatClass)) {
            case "ECONOMY" -> new BigDecimal("1.0");
            case "ECONOMY_FLEX" -> new BigDecimal("1.3");
            case "BUSINESS" -> new BigDecimal("2.5");
            case "FIRST" -> new BigDecimal("4.0");
            default -> throw PricingException.badRequest(
                    "INVALID_SEAT_CLASS",
                    "Unsupported seat class. Use ECONOMY, ECONOMY_FLEX, BUSINESS, or FIRST");
        };
    }

    private static String normalizeSeatClass(String seatClass) {
        return seatClass.trim().toUpperCase(Locale.ROOT).replace(' ', '_');
    }

    private static BigDecimal applyDiscount(Promotion promo, BigDecimal amount) {
        if ("PERCENTAGE".equalsIgnoreCase(promo.discountType)) {
            return amount.multiply(promo.discountValue).divide(HUNDRED, 2, RoundingMode.HALF_UP);
        }
        if ("FIXED".equalsIgnoreCase(promo.discountType)) {
            return promo.discountValue.min(amount);
        }
        throw PricingException.badRequest("INVALID_DISCOUNT_TYPE", "Unsupported discount type");
    }

    private static void validatePromotionRequest(CreatePromotionRequest request) {
        if (request.promoCode() == null
                || request.promoCode().isBlank()
                || request.discountType() == null
                || request.discountType().isBlank()
                || request.discountValue() == null
                || request.validFrom() == null
                || request.validUntil() == null) {
            throw PricingException.badRequest("INVALID_REQUEST", "Missing required promotion fields");
        }
        String type = request.discountType().toUpperCase(Locale.ROOT);
        if (!"PERCENTAGE".equals(type) && !"FIXED".equals(type)) {
            throw PricingException.badRequest("INVALID_DISCOUNT_TYPE", "discount_type must be PERCENTAGE or FIXED");
        }
        if (!request.validFrom().isBefore(request.validUntil())) {
            throw PricingException.badRequest("INVALID_DATES", "valid_from must be before valid_until");
        }
    }

    private static YearMonth parseMonth(String month) {
        if (month == null || month.isBlank()) {
            return YearMonth.now(ZoneOffset.UTC);
        }
        try {
            return YearMonth.parse(month);
        } catch (Exception e) {
            throw PricingException.badRequest("INVALID_MONTH", "month must be in yyyy-MM format");
        }
    }
}
