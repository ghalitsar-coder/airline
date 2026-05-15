package com.skylink.airline.exception;

public class ApiException extends RuntimeException {

    private final int status;
    private final String code;

    public ApiException(int status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public int getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    public static ApiException notFound(String message) {
        return new ApiException(404, "NOT_FOUND", message);
    }

    public static ApiException badRequest(String message) {
        return new ApiException(400, "BAD_REQUEST", message);
    }

    public static ApiException unprocessable(String message) {
        return new ApiException(422, "UNPROCESSABLE", message);
    }
}
