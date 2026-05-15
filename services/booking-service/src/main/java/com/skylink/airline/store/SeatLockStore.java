package com.skylink.airline.store;

import jakarta.enterprise.context.ApplicationScoped;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class SeatLockStore {

    private final Map<UUID, List<UUID>> locksByBooking = new ConcurrentHashMap<>();

    public void put(UUID bookingId, List<UUID> lockIds) {
        locksByBooking.put(bookingId, new ArrayList<>(lockIds));
    }

    public List<UUID> get(UUID bookingId) {
        return locksByBooking.getOrDefault(bookingId, List.of());
    }

    public List<UUID> remove(UUID bookingId) {
        List<UUID> locks = locksByBooking.remove(bookingId);
        return locks != null ? locks : List.of();
    }
}
