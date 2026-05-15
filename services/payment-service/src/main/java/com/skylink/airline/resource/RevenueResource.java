package com.skylink.airline.resource;

import com.skylink.airline.entity.RevenueAccounting;
import com.skylink.airline.service.RevenueService;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

@Path("/v1/revenue")
@Produces(MediaType.APPLICATION_JSON)
public class RevenueResource {

    @Inject
    RevenueService revenueService;

    @GET
    public List<RevenueAccounting> listRevenue() {
        return revenueService.listAll();
    }
}
