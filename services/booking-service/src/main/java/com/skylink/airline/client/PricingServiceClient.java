package com.skylink.airline.client;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.ClientDtos.PriceCalculateData;
import com.skylink.airline.dto.ClientDtos.PriceCalculateRequest;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@RegisterRestClient(configKey = "pricing-api")
@Path("/v1")
public interface PricingServiceClient {

    @POST
    @Path("/prices/calculate")
    ApiResponse<PriceCalculateData> calculatePrice(PriceCalculateRequest request);
}
