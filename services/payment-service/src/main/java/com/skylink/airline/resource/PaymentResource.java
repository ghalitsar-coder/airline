package com.skylink.airline.resource;

import com.skylink.airline.model.CreatePaymentRequest;
import com.skylink.airline.model.PaymentResponse;
import com.skylink.airline.model.RefundResponse;
import com.skylink.airline.model.WebhookPayload;
import com.skylink.airline.service.PaymentService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@Path("/v1/payments")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PaymentResource {

    @Inject
    PaymentService paymentService;

    @ConfigProperty(name = "xendit.callback-token")
    String callbackToken;

    @POST
    public PaymentResponse createPayment(CreatePaymentRequest request) {
        return paymentService.createPayment(request);
    }

    @GET
    @Path("/{id}")
    public PaymentResponse getPayment(@PathParam("id") UUID id) {
        return paymentService.getPayment(id);
    }

    @POST
    @Path("/webhook")
    public PaymentResponse webhook(
            @HeaderParam("X-CALLBACK-TOKEN") String token, WebhookPayload payload) {
        if (token == null || !token.equals(callbackToken)) {
            throw new WebApplicationException("Invalid callback token", Response.Status.UNAUTHORIZED);
        }
        return paymentService.handleWebhook(payload);
    }

    @POST
    @Path("/{id}/refund")
    public RefundResponse refund(@PathParam("id") UUID id) {
        return paymentService.refund(id);
    }
}
