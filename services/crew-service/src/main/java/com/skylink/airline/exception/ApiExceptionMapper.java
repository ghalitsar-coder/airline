package com.skylink.airline.exception;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.ErrorBody;
import com.skylink.airline.dto.Meta;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public class ApiExceptionMapper implements ExceptionMapper<ApiException> {

    @Override
    public Response toResponse(ApiException exception) {
        return Response.status(exception.getStatus())
                .entity(ApiResponse.fail(ErrorBody.of(exception.getCode(), exception.getMessage()), Meta.now()))
                .build();
    }
}
