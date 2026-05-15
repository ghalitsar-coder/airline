package com.skylink.airline.resource;

import java.util.UUID;

public final class RequestContext {

    private static final ThreadLocal<String> REQUEST_ID = new ThreadLocal<>();

    private RequestContext() {}

    public static void setRequestId(String requestId) {
        REQUEST_ID.set(requestId);
    }

    public static void clear() {
        REQUEST_ID.remove();
    }

    public static String requestId() {
        String id = REQUEST_ID.get();
        return id != null ? id : UUID.randomUUID().toString();
    }
}
