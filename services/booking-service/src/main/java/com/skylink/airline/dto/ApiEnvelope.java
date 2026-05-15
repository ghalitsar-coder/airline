package com.skylink.airline.dto;

import java.time.Instant;

public final class ApiEnvelope {

    private ApiEnvelope() {}

    public static <T> Envelope<T> ok(T data) {
        return new Envelope<>(true, data, null, meta());
    }

    public static <T> Envelope<T> created(T data) {
        return new Envelope<>(true, data, null, meta());
    }

    public static <T> Envelope<T> fail(String code, String message) {
        return new Envelope<>(false, null, new ErrorBody(code, message, null), meta());
    }

    private static Meta meta() {
        return new Meta(null, Instant.now().toString());
    }

    public record Envelope<T>(boolean success, T data, ErrorBody error, Meta meta) {}

    public record ErrorBody(String code, String message, Object details) {}

    public record Meta(String request_id, String timestamp) {}
}
