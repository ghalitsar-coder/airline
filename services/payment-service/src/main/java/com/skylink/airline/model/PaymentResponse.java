package com.skylink.airline.model;

import java.math.BigDecimal;
import java.util.UUID;

public record PaymentResponse(
        UUID paymentId,
        UUID bookingId,
        String paymentMethod,
        String paymentStatus,
        BigDecimal amount,
        String currencyCode,
        String paymentUrl) {

    public static PaymentResponse from(
            UUID paymentId,
            UUID bookingId,
            String paymentMethod,
            String paymentStatus,
            BigDecimal amount,
            String currencyCode,
            String paymentUrl) {
        return new PaymentResponse(
                paymentId, bookingId, paymentMethod, paymentStatus, amount, currencyCode, paymentUrl);
    }
}
