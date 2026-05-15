package com.skylink.airline.service;

import jakarta.enterprise.context.ApplicationScoped;
import java.util.UUID;

@ApplicationScoped
public class XenditClient {

    public XenditChargeResult createCharge(UUID paymentId) {
        String paymentUrl = "https://checkout.xendit.co/web/" + paymentId;
        return new XenditChargeResult(paymentId, paymentUrl);
    }

    public XenditRefundResult refund(UUID paymentId) {
        return new XenditRefundResult(paymentId, "REFUNDED");
    }

    public record XenditChargeResult(UUID paymentId, String paymentUrl) {
    }

    public record XenditRefundResult(UUID paymentId, String status) {
    }
}
