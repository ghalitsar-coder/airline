package com.skylink.airline.exception;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.ErrorBody;
import com.skylink.airline.dto.Meta;
import com.skylink.airline.resource.RequestContext;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public class PricingExceptionMapper implements ExceptionMapper<PricingException> {

    @Override
    public Response toResponse(PricingException exception) {
        Meta meta = Meta.now(RequestContext.requestId());
        ApiResponse<Void> body =
                ApiResponse.fail(ErrorBody.of(exception.getCode(), exception.getMessage()), meta);
        return Response.status(exception.getStatus()).entity(body).build();
    }
}
