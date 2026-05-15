package com.skylink.airline.model;

import java.util.UUID;

public record RefundResponse(UUID paymentId, String paymentStatus, String message) {
}
