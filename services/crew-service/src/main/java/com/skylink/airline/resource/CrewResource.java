package com.skylink.airline.resource;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.CrewDtos.CreateAssignmentRequest;
import com.skylink.airline.dto.CrewDtos.UpdateAssignmentRequest;
import com.skylink.airline.dto.Meta;
import com.skylink.airline.service.CrewService;
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
public class CrewResource {

    @Inject
    CrewService crewService;

    @GET
    @Path("/crew")
    public ApiResponse<?> listCrew() {
        return ApiResponse.ok(crewService.listCrew(), Meta.now());
    }

    @GET
    @Path("/crew/{id}")
    public ApiResponse<?> getCrew(@PathParam("id") UUID id) {
        return ApiResponse.ok(crewService.getCrew(id), Meta.now());
    }

    @GET
    @Path("/crew/{id}/schedule")
    public ApiResponse<?> schedule(@PathParam("id") UUID id) {
        return ApiResponse.ok(crewService.getSchedule(id), Meta.now());
    }

    @POST
    @Path("/crew/assignments")
    public Response createAssignment(CreateAssignmentRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.ok(crewService.createAssignment(request), Meta.now()))
                .build();
    }

    @PUT
    @Path("/crew/assignments/{id}")
    public ApiResponse<?> updateAssignment(
            @PathParam("id") UUID id, UpdateAssignmentRequest request) {
        return ApiResponse.ok(crewService.updateAssignment(id, request), Meta.now());
    }

    @GET
    @Path("/flights/{id}/crew")
    public ApiResponse<?> flightCrew(@PathParam("id") UUID id) {
        return ApiResponse.ok(crewService.getFlightCrew(id), Meta.now());
    }
}
