package com.skylink.airline.client;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.ClientDtos.SeatReservationData;
import com.skylink.airline.dto.ClientDtos.SeatReservationRequest;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.UUID;

@RegisterRestClient(configKey = "inventory-api")
@Path("/v1")
public interface InventoryServiceClient {

    @POST
    @Path("/seat-reservations")
    ApiResponse<SeatReservationData> createSeatReservation(SeatReservationRequest request);

    @DELETE
    @Path("/seat-reservations/{lockId}")
    void releaseSeatReservation(@PathParam("lockId") UUID lockId);
}
