package com.skylink.airline.exception;

public class BookingException extends RuntimeException {

    private final int status;
    private final String code;

    public BookingException(int status, String code, String message) {
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

    public static BookingException badRequest(String message) {
        return new BookingException(400, "BAD_REQUEST", message);
    }

    public static BookingException notFound(String message) {
        return new BookingException(404, "NOT_FOUND", message);
    }

    public static BookingException conflict(String message) {
        return new BookingException(409, "CONFLICT", message);
    }

    public static BookingException unprocessable(String message) {
        return new BookingException(422, "UNPROCESSABLE", message);
    }

    public static BookingException failedDependency(String message) {
        return new BookingException(424, "FAILED_DEPENDENCY", message);
    }
}
