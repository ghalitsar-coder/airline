package com.skylink.airline.service;

import com.skylink.airline.model.PaymentResponse;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class IdempotencyService {

    private final ConcurrentHashMap<String, PaymentResponse> store = new ConcurrentHashMap<>();

    public Optional<PaymentResponse> get(String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return Optional.empty();
        }
        return Optional.ofNullable(store.get(idempotencyKey));
    }

    public void put(String idempotencyKey, PaymentResponse response) {
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            store.put(idempotencyKey, response);
        }
    }
}
