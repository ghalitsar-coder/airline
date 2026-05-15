package com.skylink.airline.model;

import java.util.UUID;

public record WebhookPayload(UUID paymentId, String status) {
}
