package com.skylink.airline.dto;

import com.skylink.airline.entity.FlightPrice;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record FlightPriceDto(
        UUID priceId,
        UUID flightId,
        String seatClass,
        String fareBasis,
        BigDecimal basePrice,
        BigDecimal taxAmount,
        String currencyCode,
        Instant validFrom,
        Instant validUntil) {

    public static FlightPriceDto from(FlightPrice entity) {
        return new FlightPriceDto(
                entity.priceId,
                entity.flightId,
                entity.seatClass,
                entity.fareBasis,
                entity.basePrice,
                entity.taxAmount,
                entity.currencyCode,
                entity.validFrom,
                entity.validUntil);
    }
}
