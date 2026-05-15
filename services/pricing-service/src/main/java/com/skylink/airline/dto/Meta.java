package com.skylink.airline.dto;

import java.time.Instant;

public record Meta(String requestId, Instant timestamp) {

    public static Meta now(String requestId) {
        return new Meta(requestId, Instant.now());
    }
}
