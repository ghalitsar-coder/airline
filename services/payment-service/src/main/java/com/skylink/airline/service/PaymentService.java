package com.skylink.airline.service;

import com.skylink.airline.entity.Payment;
import com.skylink.airline.messaging.PaymentEventPublisher;
import com.skylink.airline.model.CreatePaymentRequest;
import com.skylink.airline.model.PaymentResponse;
import com.skylink.airline.model.RefundResponse;
import com.skylink.airline.model.WebhookPayload;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@ApplicationScoped
public class PaymentService {

    @Inject
    IdempotencyService idempotencyService;

    @Inject
    XenditClient xenditClient;

    @Inject
    PaymentEventPublisher eventPublisher;

    @Transactional
    public PaymentResponse createPayment(CreatePaymentRequest request) {
        if (request.bookingId() == null || request.amount() == null || request.paymentMethod() == null) {
            throw badRequest("booking_id, amount, and payment_method are required");
        }

        var cached = idempotencyService.get(request.idempotencyKey());
        if (cached.isPresent()) {
            return cached.get();
        }

        Payment payment = new Payment();
        payment.bookingId = request.bookingId();
        payment.amount = request.amount();
        payment.paymentMethod = request.paymentMethod();
        payment.paymentStatus = "PENDING";
        payment.persist();

        var charge = xenditClient.createCharge(payment.paymentId);
        PaymentResponse response = PaymentResponse.from(
                payment.paymentId,
                payment.bookingId,
                payment.paymentMethod,
                payment.paymentStatus,
                payment.amount,
                payment.currencyCode,
                charge.paymentUrl());

        idempotencyService.put(request.idempotencyKey(), response);
        return response;
    }

    public PaymentResponse getPayment(UUID id) {
        Payment payment = Payment.findById(id);
        if (payment == null) {
            throw new NotFoundException("Payment not found");
        }
        return toResponse(payment, null);
    }

    @Transactional
    public PaymentResponse handleWebhook(WebhookPayload payload) {
        if (payload.paymentId() == null || payload.status() == null) {
            throw badRequest("payment_id and status are required");
        }

        String status = payload.status().toUpperCase();
        if (!status.equals("COMPLETED") && !status.equals("FAILED")) {
            throw badRequest("status must be COMPLETED or FAILED");
        }

        Payment payment = Payment.findById(payload.paymentId());
        if (payment == null) {
            throw new NotFoundException("Payment not found");
        }

        payment.paymentStatus = status;
        payment.persist();

        if ("COMPLETED".equals(status)) {
            eventPublisher.publishCompleted(payment);
        } else {
            eventPublisher.publishFailed(payment);
        }

        return toResponse(payment, null);
    }

    @Transactional
    public RefundResponse refund(UUID id) {
        Payment payment = Payment.findById(id);
        if (payment == null) {
            throw new NotFoundException("Payment not found");
        }
        if (!"COMPLETED".equals(payment.paymentStatus)) {
            throw badRequest("Only completed payments can be refunded");
        }

        xenditClient.refund(payment.paymentId);
        payment.paymentStatus = "REFUNDED";
        payment.persist();

        return new RefundResponse(payment.paymentId, payment.paymentStatus, "Refund initiated");
    }

    private PaymentResponse toResponse(Payment payment, String paymentUrl) {
        return PaymentResponse.from(
                payment.paymentId,
                payment.bookingId,
                payment.paymentMethod,
                payment.paymentStatus,
                payment.amount,
                payment.currencyCode,
                paymentUrl);
    }

    private WebApplicationException badRequest(String message) {
        return new WebApplicationException(message, Response.Status.BAD_REQUEST);
    }
}
