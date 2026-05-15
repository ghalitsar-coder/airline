package com.skylink.airline.resource;

import com.skylink.airline.dto.ApiEnvelope;
import com.skylink.airline.dto.BookingDtos;
import com.skylink.airline.entity.Baggage;
import com.skylink.airline.service.BookingService;
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

@Path("/v1/bookings")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BookingResource {

    @Inject
    BookingService bookingService;

    @POST
    public Response create(BookingDtos.CreateBookingRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ApiEnvelope.ok(bookingService.createBooking(request)))
                .build();
    }

    @GET
    @Path("/{pnr}")
    public Response get(@PathParam("pnr") String pnr) {
        return Response.ok(ApiEnvelope.ok(bookingService.getByPnr(pnr))).build();
    }

    @PUT
    @Path("/{pnr}/confirm")
    public Response confirm(@PathParam("pnr") String pnr, BookingDtos.ConfirmBookingRequest request) {
        Boolean releaseLocks = request != null ? request.release_locks() : null;
        return Response.ok(ApiEnvelope.ok(bookingService.confirm(pnr, releaseLocks))).build();
    }

    @PUT
    @Path("/{pnr}/cancel")
    public Response cancel(@PathParam("pnr") String pnr) {
        return Response.ok(ApiEnvelope.ok(bookingService.cancel(pnr))).build();
    }

    @PUT
    @Path("/{pnr}/change")
    public Response change(@PathParam("pnr") String pnr) {
        return Response.ok(ApiEnvelope.ok(bookingService.change(pnr))).build();
    }

    @POST
    @Path("/{pnr}/check-in")
    public Response checkIn(@PathParam("pnr") String pnr, BookingDtos.CheckInRequest request) {
        return Response.ok(ApiEnvelope.ok(bookingService.checkIn(pnr, request))).build();
    }

    @POST
    @Path("/{pnr}/baggage")
    public Response baggage(@PathParam("pnr") String pnr, BookingDtos.BaggageRequest request) {
        Baggage baggage = bookingService.addBaggage(pnr, request);
        return Response.status(Response.Status.CREATED)
                .entity(ApiEnvelope.ok(baggage))
                .build();
    }

    @GET
    @Path("/{pnr}/boarding-pass")
    public Response boardingPass(@PathParam("pnr") String pnr) {
        return Response.ok(ApiEnvelope.ok(bookingService.boardingPass(pnr))).build();
    }
}
