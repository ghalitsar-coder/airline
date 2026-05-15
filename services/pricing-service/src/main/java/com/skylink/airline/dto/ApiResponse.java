package com.skylink.airline.dto;

public record ApiResponse<T>(boolean success, T data, ErrorBody error, Meta meta) {

    public static <T> ApiResponse<T> ok(T data, Meta meta) {
        return new ApiResponse<>(true, data, null, meta);
    }

    public static <T> ApiResponse<T> fail(ErrorBody error, Meta meta) {
        return new ApiResponse<>(false, null, error, meta);
    }
}
