package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ApiResponse<T>(
        boolean success,
        T data,
        ErrorBody error,
        Meta meta) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ErrorBody(String code, String message, Object details) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Meta(String request_id, String timestamp) {}
}
