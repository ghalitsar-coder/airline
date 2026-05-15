package com.skylink.airline.resource;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.ext.Provider;
import java.util.UUID;

@Provider
public class RequestIdFilter implements ContainerRequestFilter, ContainerResponseFilter {

    private static final String HEADER = "X-Request-ID";

    @Override
    public void filter(ContainerRequestContext requestContext) {
        String requestId = requestContext.getHeaderString(HEADER);
        if (requestId == null || requestId.isBlank()) {
            requestId = "req_" + UUID.randomUUID();
        }
        RequestContext.setRequestId(requestId);
    }

    @Override
    public void filter(
            ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
        RequestContext.clear();
    }
}
