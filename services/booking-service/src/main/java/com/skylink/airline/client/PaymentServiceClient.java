package com.skylink.airline.client;

import com.skylink.airline.dto.ApiResponse;
import com.skylink.airline.dto.ClientDtos.PaymentInitData;
import com.skylink.airline.dto.ClientDtos.PaymentInitRequest;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@RegisterRestClient(configKey = "payment-api")
@Path("/v1")
public interface PaymentServiceClient {

    @POST
    @Path("/payments")
    ApiResponse<PaymentInitData> initPayment(PaymentInitRequest request);
}
