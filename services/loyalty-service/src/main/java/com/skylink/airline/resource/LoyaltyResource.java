package com.skylink.airline.resource;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.LoyaltyDtos.EarnRequest;
import com.skylink.airline.dto.LoyaltyDtos.RedeemRequest;
import com.skylink.airline.dto.LoyaltyDtos.ReverseMilesRequest;
import com.skylink.airline.dto.Meta;
import com.skylink.airline.service.LoyaltyService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@Path("/v1/loyalty")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class LoyaltyResource {

    @Inject
    LoyaltyService loyaltyService;

    @GET
    @Path("/tiers")
    public ApiResponse<?> tiers() {
        return ApiResponse.ok(loyaltyService.listTiers(), Meta.now());
    }

    @GET
    @Path("/{passengerId}")
    public ApiResponse<?> getAccount(@PathParam("passengerId") UUID passengerId) {
        return ApiResponse.ok(loyaltyService.getByPassengerId(passengerId), Meta.now());
    }

    @GET
    @Path("/{passengerId}/transactions")
    public ApiResponse<?> transactions(@PathParam("passengerId") UUID passengerId) {
        return ApiResponse.ok(loyaltyService.listTransactions(passengerId), Meta.now());
    }

    @POST
    @Path("/{passengerId}/redeem")
    public ApiResponse<?> redeem(@PathParam("passengerId") UUID passengerId, RedeemRequest request) {
        return ApiResponse.ok(loyaltyService.redeem(passengerId, request.miles()), Meta.now());
    }

    @POST
    @Path("/{passengerId}/reverse-miles")
    public ApiResponse<?> reverseMiles(
            @PathParam("passengerId") UUID passengerId, ReverseMilesRequest request) {
        return ApiResponse.ok(
                loyaltyService.reverseMiles(passengerId, request.miles(), request.reason()), Meta.now());
    }

    @POST
    @Path("/{passengerId}/earn")
    public Response earn(@PathParam("passengerId") UUID passengerId, EarnRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.ok(loyaltyService.earn(passengerId, request), Meta.now()))
                .build();
    }
}
