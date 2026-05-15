package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CalculateResult(
        @JsonProperty("flight_id") UUID flightId,
        @JsonProperty("seat_class") String seatClass,
        @JsonProperty("base_fare") BigDecimal baseFare,
        @JsonProperty("class_multiplier") BigDecimal classMultiplier,
        @JsonProperty("subtotal") BigDecimal subtotal,
        @JsonProperty("tax_breakdown") List<TaxLine> taxBreakdown,
        @JsonProperty("tax_total") BigDecimal taxTotal,
        @JsonProperty("promo_code") String promoCode,
        @JsonProperty("discount") BigDecimal discount,
        @JsonProperty("total_per_passenger") BigDecimal totalPerPassenger,
        @JsonProperty("passenger_count") int passengerCount,
        @JsonProperty("grand_total") BigDecimal grandTotal,
        @JsonProperty("currency_code") String currencyCode) {

    public record TaxLine(String taxName, BigDecimal percentage, BigDecimal amount) {}
}
