package com.skylink.airline.exception;

public class PricingException extends RuntimeException {

    private final String code;
    private final int status;

    private PricingException(String code, String message, int status) {
        super(message);
        this.code = code;
        this.status = status;
    }

    public String getCode() {
        return code;
    }

    public int getStatus() {
        return status;
    }

    public static PricingException notFound(String code, String message) {
        return new PricingException(code, message, 404);
    }

    public static PricingException badRequest(String code, String message) {
        return new PricingException(code, message, 400);
    }

    public static PricingException conflict(String code, String message) {
        return new PricingException(code, message, 409);
    }

    public static PricingException unprocessable(String code, String message) {
        return new PricingException(code, message, 422);
    }
}
