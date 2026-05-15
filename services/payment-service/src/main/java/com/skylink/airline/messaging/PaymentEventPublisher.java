package com.skylink.airline.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.skylink.airline.entity.Payment;
import io.smallrye.reactive.messaging.rabbitmq.OutgoingRabbitMQMetadata;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.eclipse.microprofile.reactive.messaging.Metadata;
import org.jboss.logging.Logger;

@ApplicationScoped
public class PaymentEventPublisher {

    private static final Logger LOG = Logger.getLogger(PaymentEventPublisher.class);

    @Inject
    @Channel("payment-events")
    Emitter<String> emitter;

    @Inject
    ObjectMapper objectMapper;

    public void publishCompleted(Payment payment) {
        publish("payment.completed", payment);
    }

    public void publishFailed(Payment payment) {
        publish("payment.failed", payment);
    }

    private void publish(String routingKey, Payment payment) {
        try {
            Map<String, Object> envelope = new HashMap<>();
            envelope.put("event_id", UUID.randomUUID().toString());
            envelope.put("event_type", routingKey.equals("payment.completed") ? "PaymentCompleted" : "PaymentFailed");
            envelope.put("source_service", "payment-service");
            envelope.put("timestamp", Instant.now().toString());
            Map<String, Object> payload = new HashMap<>();
            payload.put("payment_id", payment.paymentId.toString());
            payload.put("booking_id", payment.bookingId.toString());
            payload.put("amount", payment.amount);
            payload.put("currency", payment.currencyCode);
            payload.put("status", payment.paymentStatus);
            envelope.put("payload", payload);

            String body = objectMapper.writeValueAsString(envelope);
            OutgoingRabbitMQMetadata metadata = OutgoingRabbitMQMetadata.builder()
                    .withRoutingKey(routingKey)
                    .build();
            emitter.send(Message.of(body, Metadata.of(metadata)));
        } catch (Exception e) {
            LOG.warnf("Failed to publish payment event to RabbitMQ: %s", e.getMessage());
        }
    }
}
