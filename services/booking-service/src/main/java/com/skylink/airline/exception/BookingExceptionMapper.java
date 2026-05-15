package com.skylink.airline.exception;

import com.skylink.airline.dto.ApiEnvelope;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public class BookingExceptionMapper implements ExceptionMapper<BookingException> {

    @Override
    public Response toResponse(BookingException exception) {
        return Response.status(exception.getStatus())
                .entity(ApiEnvelope.fail(exception.getCode(), exception.getMessage()))
                .build();
    }
}
