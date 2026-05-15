package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class BookingDtos {

    private BookingDtos() {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record CreateBookingRequest(
            UUID primary_passenger_id,
            List<PassengerInput> passengers,
            List<SegmentInput> segments,
            String promo_code,
            UUID idempotency_key) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record PassengerInput(
            UUID passenger_id,
            String first_name,
            String last_name,
            String type) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record SegmentInput(
            UUID flight_id,
            UUID seat_id,
            String seat_class,
            UUID aircraft_id,
            String booking_session_id) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record CreateBookingResponse(
            String pnr,
            UUID booking_id,
            String payment_url,
            List<UUID> lock_ids,
            BigDecimal total_amount) {}

    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record BookingDetailResponse(
            String pnr,
            UUID booking_id,
            UUID primary_passenger_id,
            String status,
            BigDecimal total_amount,
            String currency_code,
            Instant booking_date,
            List<PassengerDetail> passengers,
            List<SegmentDetail> segments) {}

    public record PassengerDetail(
            UUID booking_passenger_id,
            UUID passenger_id,
            String passenger_type,
            String first_name,
            String last_name) {}

    public record SegmentDetail(
            UUID segment_id,
            UUID flight_id,
            UUID seat_id,
            String seat_class,
            String status) {}

    public record ConfirmBookingRequest(Boolean release_locks) {}

    public record CheckInRequest(List<UUID> segment_ids, String check_in_method) {}

    public record BaggageRequest(
            UUID segment_id,
            BigDecimal weight_kg,
            String baggage_type,
            String tag_number) {}

    public record BoardingPassResponse(String boarding_pass_url) {}
}
