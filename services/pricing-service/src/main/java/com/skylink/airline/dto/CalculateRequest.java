package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.UUID;

public record CalculateRequest(
        @JsonProperty("flight_id") UUID flightId,
        @JsonProperty("seat_class") String seatClass,
        @JsonProperty("promo_code") String promoCode,
        @JsonProperty("passenger_count") Integer passengerCount) {

    public int effectivePassengerCount() {
        return passengerCount == null || passengerCount < 1 ? 1 : passengerCount;
    }
}
