package com.skylink.airline.resource;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.CalculateRequest;
import com.skylink.airline.dto.CalculateResult;
import com.skylink.airline.dto.CalendarDayPrice;
import com.skylink.airline.dto.CreatePromotionRequest;
import com.skylink.airline.dto.FlightPriceDto;
import com.skylink.airline.dto.Meta;
import com.skylink.airline.dto.PromotionDto;
import com.skylink.airline.service.PricingService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/v1")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PricingResource {

    @Inject
    PricingService pricingService;

    @GET
    @Path("/prices/search")
    public ApiResponse<List<FlightPriceDto>> search(
            @QueryParam("origin") String origin,
            @QueryParam("destination") String destination,
            @QueryParam("date") String date) {
        List<FlightPriceDto> data = pricingService.searchPrices(origin, destination, date);
        return ApiResponse.ok(data, Meta.now(RequestContext.requestId()));
    }

    @GET
    @Path("/prices/calendar")
    public ApiResponse<List<CalendarDayPrice>> calendar(
            @QueryParam("route_id") String routeId, @QueryParam("month") String month) {
        List<CalendarDayPrice> data = pricingService.calendarPrices(routeId, month);
        return ApiResponse.ok(data, Meta.now(RequestContext.requestId()));
    }

    @GET
    @Path("/prices/{flightId}")
    public ApiResponse<List<FlightPriceDto>> pricesByFlight(@PathParam("flightId") UUID flightId) {
        List<FlightPriceDto> data = pricingService.getPricesByFlight(flightId);
        return ApiResponse.ok(data, Meta.now(RequestContext.requestId()));
    }

    @POST
    @Path("/prices/calculate")
    public ApiResponse<CalculateResult> calculate(CalculateRequest request) {
        CalculateResult data = pricingService.calculate(request);
        return ApiResponse.ok(data, Meta.now(RequestContext.requestId()));
    }

    @GET
    @Path("/promotions")
    public ApiResponse<List<PromotionDto>> listPromotions() {
        List<PromotionDto> data = pricingService.listActivePromotions();
        return ApiResponse.ok(data, Meta.now(RequestContext.requestId()));
    }

    @POST
    @Path("/promotions")
    public Response createPromotion(CreatePromotionRequest request) {
        PromotionDto data = pricingService.createPromotion(request);
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.ok(data, Meta.now(RequestContext.requestId())))
                .build();
    }
}
