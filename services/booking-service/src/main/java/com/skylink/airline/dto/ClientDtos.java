package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public final class ClientDtos {

    private ClientDtos() {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PassengerValidateData(boolean valid, boolean has_valid_passport) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record SeatReservationRequest(
            UUID flight_id,
            UUID seat_id,
            String booking_session_id,
            Integer ttl_seconds) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record SeatReservationData(UUID lock_id, UUID flight_id, UUID seat_id, String status) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PriceCalculateRequest(
            UUID primary_passenger_id,
            List<BookingDtos.PassengerInput> passengers,
            List<BookingDtos.SegmentInput> segments,
            String promo_code) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PriceCalculateData(
            BigDecimal total_amount,
            String currency_code,
            BigDecimal base_fare,
            BigDecimal taxes,
            BigDecimal discount) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PaymentInitRequest(
            UUID booking_id,
            BigDecimal amount,
            String currency_code,
            UUID idempotency_key,
            String payment_method) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PaymentInitData(UUID payment_id, String payment_url, String payment_status) {}
}
