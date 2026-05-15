package com.skylink.airline.resource;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.MaintenanceDtos.CreateMaintenanceRequest;
import com.skylink.airline.dto.MaintenanceDtos.StatusUpdateRequest;
import com.skylink.airline.dto.Meta;
import com.skylink.airline.service.MaintenanceService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@Path("/v1")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MaintenanceResource {

    @Inject
    MaintenanceService maintenanceService;

    @GET
    @Path("/maintenance")
    public ApiResponse<?> list() {
        return ApiResponse.ok(maintenanceService.listAll(), Meta.now());
    }

    @POST
    @Path("/maintenance")
    public Response create(CreateMaintenanceRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.ok(maintenanceService.create(request), Meta.now()))
                .build();
    }

    @GET
    @Path("/maintenance/{id}")
    public ApiResponse<?> get(@PathParam("id") UUID id) {
        return ApiResponse.ok(maintenanceService.getById(id), Meta.now());
    }

    @PUT
    @Path("/maintenance/{id}/status")
    public ApiResponse<?> updateStatus(@PathParam("id") UUID id, StatusUpdateRequest request) {
        return ApiResponse.ok(maintenanceService.updateStatus(id, request.status()), Meta.now());
    }

    @POST
    @Path("/maintenance/{id}/approve")
    public ApiResponse<?> approve(@PathParam("id") UUID id) {
        return ApiResponse.ok(maintenanceService.approve(id), Meta.now());
    }

    @GET
    @Path("/aircrafts/{id}/maintenance-history")
    public ApiResponse<?> history(@PathParam("id") UUID id) {
        return ApiResponse.ok(maintenanceService.historyByAircraft(id), Meta.now());
    }
}
