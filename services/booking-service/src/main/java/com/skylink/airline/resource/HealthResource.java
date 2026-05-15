package com.skylink.airline.resource;

import com.skylink.airline.dto.ApiEnvelope;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/health")
@Produces(MediaType.APPLICATION_JSON)
public class HealthResource {

    @GET
    public Response health() {
        return Response.ok(ApiEnvelope.ok(Map.of(
                "status", "ok",
                "service", "booking-service"))).build();
    }
}
