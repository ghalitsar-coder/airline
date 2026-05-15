package com.skylink.airline.model;

import java.math.BigDecimal;
import java.util.UUID;

public record CreatePaymentRequest(
        UUID bookingId,
        BigDecimal amount,
        String paymentMethod,
        String idempotencyKey) {
}
