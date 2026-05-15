package com.skylink.airline.client;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.ClientDtos.PassengerValidateData;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.UUID;

@RegisterRestClient(configKey = "passenger-api")
@Path("/v1/internal/passengers")
public interface PassengerServiceClient {

    @GET
    @Path("/{id}/validate")
    ApiResponse<PassengerValidateData> validatePassenger(
            @PathParam("id") UUID id,
            @HeaderParam("X-Service-Key") String serviceKey);
}
