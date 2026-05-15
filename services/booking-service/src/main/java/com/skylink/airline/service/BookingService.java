package com.skylink.airline.service;

import com.skylink.airline.client.InventoryServiceClient;
import com.skylink.airline.client.PassengerServiceClient;
import com.skylink.airline.client.PaymentServiceClient;
import com.skylink.airline.client.PricingServiceClient;
import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.BookingDtos;
import com.skylink.airline.dto.ClientDtos;
import com.skylink.airline.entity.Baggage;
import com.skylink.airline.entity.Booking;
import com.skylink.airline.entity.BookingPassenger;
import com.skylink.airline.entity.BookingSegment;
import com.skylink.airline.entity.CheckIn;
import com.skylink.airline.exception.BookingException;
import com.skylink.airline.store.SeatLockStore;
import com.skylink.airline.util.PnrGenerator;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.WebApplicationException;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

@ApplicationScoped
public class BookingService {

    @Inject
    @RestClient
    PassengerServiceClient passengerClient;

    @Inject
    @RestClient
    InventoryServiceClient inventoryClient;

    @Inject
    @RestClient
    PricingServiceClient pricingClient;

    @Inject
    @RestClient
    PaymentServiceClient paymentClient;

    @Inject
    SeatLockStore seatLockStore;

    @ConfigProperty(name = "passenger.service.api-key")
    String passengerApiKey;

    @Transactional
    public BookingDtos.CreateBookingResponse createBooking(BookingDtos.CreateBookingRequest request) {
        validateCreateRequest(request);

        ApiResponse<ClientDtos.PassengerValidateData> validation =
                passengerClient.validatePassenger(request.primary_passenger_id(), passengerApiKey);
        if (validation == null || !validation.success() || validation.data() == null || !validation.data().valid()) {
            throw BookingException.unprocessable("Primary passenger validation failed");
        }

        List<UUID> lockIds = new ArrayList<>();
        try {
            for (BookingDtos.SegmentInput segment : request.segments()) {
                ApiResponse<ClientDtos.SeatReservationData> lockResponse = inventoryClient.createSeatReservation(
                        new ClientDtos.SeatReservationRequest(
                                segment.flight_id(),
                                segment.seat_id(),
                                segment.booking_session_id(),
                                null));
                if (lockResponse == null || !lockResponse.success() || lockResponse.data() == null) {
                    throw BookingException.conflict("Unable to lock seat for flight " + segment.flight_id());
                }
                lockIds.add(lockResponse.data().lock_id());
            }

            ClientDtos.PriceCalculateData pricing = calculatePrice(request);
            BigDecimal totalAmount = pricing.total_amount();
            String currency = pricing.currency_code() != null ? pricing.currency_code() : "IDR";

            Booking booking = new Booking();
            booking.bookingReference = PnrGenerator.generateUnique();
            booking.primaryPassengerId = request.primary_passenger_id();
            booking.status = "PENDING";
            booking.totalAmount = totalAmount;
            booking.currencyCode = currency;
            booking.persist();

            List<BookingPassenger> savedPassengers = persistPassengers(booking.bookingId, request.passengers());
            persistSegments(booking.bookingId, request.segments(), savedPassengers);

            seatLockStore.put(booking.bookingId, lockIds);

            String paymentUrl = initPayment(booking, request.idempotency_key(), currency);

            return new BookingDtos.CreateBookingResponse(
                    booking.bookingReference,
                    booking.bookingId,
                    paymentUrl,
                    lockIds,
                    totalAmount);
        } catch (BookingException e) {
            releaseLocks(lockIds);
            throw e;
        } catch (WebApplicationException e) {
            releaseLocks(lockIds);
            throw mapClientError(e, "Booking saga failed");
        } catch (Exception e) {
            releaseLocks(lockIds);
            throw BookingException.failedDependency("Booking saga failed: " + e.getMessage());
        }
    }

    public BookingDtos.BookingDetailResponse getByPnr(String pnr) {
        Booking booking = Booking.findByReference(pnr)
                .orElseThrow(() -> BookingException.notFound("Booking not found"));

        List<BookingPassenger> passengers = BookingPassenger.listByBooking(booking.bookingId);
        List<BookingSegment> segments = BookingSegment.listByBooking(booking.bookingId);

        return new BookingDtos.BookingDetailResponse(
                booking.bookingReference,
                booking.bookingId,
                booking.primaryPassengerId,
                booking.status,
                booking.totalAmount,
                booking.currencyCode,
                booking.bookingDate,
                passengers.stream()
                        .map(p -> new BookingDtos.PassengerDetail(
                                p.bookingPassengerId,
                                p.passengerId,
                                p.passengerType,
                                p.firstName,
                                p.lastName))
                        .toList(),
                segments.stream()
                        .map(s -> new BookingDtos.SegmentDetail(
                                s.segmentId,
                                s.flightId,
                                s.seatId,
                                s.seatClass,
                                s.status))
                        .toList());
    }

    @Transactional
    public BookingDtos.BookingDetailResponse confirm(String pnr, Boolean releaseLocks) {
        Booking booking = requireBooking(pnr);
        if ("CANCELLED".equals(booking.status)) {
            throw BookingException.conflict("Booking is cancelled");
        }
        booking.status = "CONFIRMED";
        BookingSegment.update("status = ?1 where bookingId = ?2", "CONFIRMED", booking.bookingId);

        if (Boolean.TRUE.equals(releaseLocks)) {
            releaseLocksForBooking(booking.bookingId);
        }

        return getByPnr(pnr);
    }

    @Transactional
    public BookingDtos.BookingDetailResponse cancel(String pnr) {
        Booking booking = requireBooking(pnr);
        if ("CANCELLED".equals(booking.status)) {
            return getByPnr(pnr);
        }
        booking.status = "CANCELLED";
        BookingSegment.update("status = ?1 where bookingId = ?2", "CANCELLED", booking.bookingId);
        releaseLocksForBooking(booking.bookingId);
        return getByPnr(pnr);
    }

    public BookingDtos.BookingDetailResponse change(String pnr) {
        requireBooking(pnr);
        return getByPnr(pnr);
    }

    @Transactional
    public BookingDtos.BookingDetailResponse checkIn(String pnr, BookingDtos.CheckInRequest request) {
        Booking booking = requireBooking(pnr);
        if (!"CONFIRMED".equals(booking.status)) {
            throw BookingException.unprocessable("Booking must be CONFIRMED to check in");
        }

        String method = request != null && request.check_in_method() != null
                ? request.check_in_method()
                : "ONLINE";

        List<BookingSegment> segments = BookingSegment.listByBooking(booking.bookingId);
        List<UUID> targetSegmentIds = request != null && request.segment_ids() != null && !request.segment_ids().isEmpty()
                ? request.segment_ids()
                : segments.stream().map(s -> s.segmentId).toList();

        for (UUID segmentId : targetSegmentIds) {
            BookingSegment segment = BookingSegment.findByIdAndBooking(segmentId, booking.bookingId)
                    .orElseThrow(() -> BookingException.notFound("Segment not found for booking"));
            if (CheckIn.findBySegment(segment.segmentId).isPresent()) {
                continue;
            }
            CheckIn checkIn = new CheckIn();
            checkIn.segmentId = segment.segmentId;
            checkIn.checkInMethod = method;
            checkIn.boardingPassIssued = true;
            checkIn.persist();
            segment.status = "CHECKED_IN";
        }

        return getByPnr(pnr);
    }

    @Transactional
    public Baggage addBaggage(String pnr, BookingDtos.BaggageRequest request) {
        Booking booking = requireBooking(pnr);
        if (request == null || request.segment_id() == null) {
            throw BookingException.badRequest("segment_id is required");
        }
        if (request.weight_kg() == null || request.weight_kg().signum() <= 0) {
            throw BookingException.badRequest("weight_kg must be positive");
        }

        BookingSegment segment = BookingSegment.findByIdAndBooking(request.segment_id(), booking.bookingId)
                .orElseThrow(() -> BookingException.notFound("Segment not found for booking"));

        Baggage baggage = new Baggage();
        baggage.segmentId = segment.segmentId;
        baggage.weightKg = request.weight_kg();
        baggage.baggageType = request.baggage_type() != null ? request.baggage_type() : "CHECKED";
        baggage.tagNumber = request.tag_number() != null
                ? request.tag_number()
                : "BAG" + String.format("%06d", ThreadLocalRandom.current().nextInt(1_000_000));
        baggage.persist();
        return baggage;
    }

    public BookingDtos.BoardingPassResponse boardingPass(String pnr) {
        requireBooking(pnr);
        return new BookingDtos.BoardingPassResponse(
                "https://storage.skylink.local/boarding-passes/" + pnr + ".pdf");
    }

    private Booking requireBooking(String pnr) {
        return Booking.findByReference(pnr)
                .orElseThrow(() -> BookingException.notFound("Booking not found"));
    }

    private void validateCreateRequest(BookingDtos.CreateBookingRequest request) {
        if (request == null) {
            throw BookingException.badRequest("Request body is required");
        }
        if (request.primary_passenger_id() == null) {
            throw BookingException.badRequest("primary_passenger_id is required");
        }
        if (request.passengers() == null || request.passengers().isEmpty()) {
            throw BookingException.badRequest("passengers is required");
        }
        if (request.segments() == null || request.segments().isEmpty()) {
            throw BookingException.badRequest("segments is required");
        }
        if (request.idempotency_key() == null) {
            throw BookingException.badRequest("idempotency_key is required");
        }
        for (BookingDtos.SegmentInput segment : request.segments()) {
            if (segment.flight_id() == null || segment.seat_id() == null || segment.booking_session_id() == null) {
                throw BookingException.badRequest("Each segment requires flight_id, seat_id, and booking_session_id");
            }
        }
    }

    private ClientDtos.PriceCalculateData calculatePrice(BookingDtos.CreateBookingRequest request) {
        try {
            ApiResponse<ClientDtos.PriceCalculateData> response = pricingClient.calculatePrice(
                    new ClientDtos.PriceCalculateRequest(
                            request.primary_passenger_id(),
                            request.passengers(),
                            request.segments(),
                            request.promo_code()));
            if (response != null && response.success() && response.data() != null) {
                return response.data();
            }
        } catch (Exception ignored) {
            // fallback for MVP when pricing service is unavailable
        }
        return fallbackPrice(request);
    }

    private ClientDtos.PriceCalculateData fallbackPrice(BookingDtos.CreateBookingRequest request) {
        int passengerCount = request.passengers().size();
        int segmentCount = request.segments().size();
        BigDecimal base = BigDecimal.valueOf(850_000L * (long) passengerCount * segmentCount);
        BigDecimal taxes = base.multiply(BigDecimal.valueOf(0.11));
        BigDecimal discount = "EARLYBIRD10".equalsIgnoreCase(request.promo_code())
                ? base.multiply(BigDecimal.valueOf(0.10))
                : BigDecimal.ZERO;
        BigDecimal total = base.add(taxes).subtract(discount);
        return new ClientDtos.PriceCalculateData(total, "IDR", base, taxes, discount);
    }

    private String initPayment(Booking booking, UUID idempotencyKey, String currency) {
        try {
            ApiResponse<ClientDtos.PaymentInitData> response = paymentClient.initPayment(
                    new ClientDtos.PaymentInitRequest(
                            booking.bookingId,
                            booking.totalAmount,
                            currency,
                            idempotencyKey,
                            "CREDIT_CARD"));
            if (response != null && response.success() && response.data() != null && response.data().payment_url() != null) {
                return response.data().payment_url();
            }
        } catch (Exception ignored) {
            // fallback when payment service is unavailable
        }
        return "https://pay.skylink.local/checkout/" + booking.bookingId;
    }

    private List<BookingPassenger> persistPassengers(UUID bookingId, List<BookingDtos.PassengerInput> passengers) {
        List<BookingPassenger> saved = new ArrayList<>();
        for (BookingDtos.PassengerInput input : passengers) {
            BookingPassenger passenger = new BookingPassenger();
            passenger.bookingId = bookingId;
            passenger.passengerId = input.passenger_id();
            passenger.passengerType = input.type() != null ? input.type() : "ADULT";
            passenger.firstName = input.first_name();
            passenger.lastName = input.last_name();
            passenger.persist();
            saved.add(passenger);
        }
        return saved;
    }

    private void persistSegments(
            UUID bookingId,
            List<BookingDtos.SegmentInput> segments,
            List<BookingPassenger> passengers) {
        for (int i = 0; i < segments.size(); i++) {
            BookingDtos.SegmentInput input = segments.get(i);
            BookingPassenger passenger = passengers.get(Math.min(i, passengers.size() - 1));

            BookingSegment segment = new BookingSegment();
            segment.bookingId = bookingId;
            segment.bookingPassengerId = passenger.bookingPassengerId;
            segment.flightId = input.flight_id();
            segment.seatId = input.seat_id();
            segment.seatClass = input.seat_class();
            segment.status = "PENDING";
            segment.persist();
        }
    }

    private void releaseLocksForBooking(UUID bookingId) {
        List<UUID> lockIds = seatLockStore.remove(bookingId);
        releaseLocks(lockIds);
    }

    private void releaseLocks(List<UUID> lockIds) {
        for (UUID lockId : lockIds) {
            try {
                inventoryClient.releaseSeatReservation(lockId);
            } catch (Exception ignored) {
                // best-effort compensation
            }
        }
    }

    private BookingException mapClientError(WebApplicationException e, String fallback) {
        int status = e.getResponse() != null ? e.getResponse().getStatus() : 502;
        if (status == 409) {
            return BookingException.conflict(fallback);
        }
        if (status == 404) {
            return BookingException.notFound(fallback);
        }
        if (status >= 400 && status < 500) {
            return BookingException.badRequest(fallback);
        }
        return BookingException.failedDependency(fallback);
    }
}
