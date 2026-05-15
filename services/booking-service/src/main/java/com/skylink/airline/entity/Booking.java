package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Entity
@Table(name = "bookings")
public class Booking extends PanacheEntityBase {

    @Id
    @Column(name = "booking_id")
    public UUID bookingId;

    @Column(name = "booking_reference", nullable = false, unique = true, length = 10)
    public String bookingReference;

    @Column(name = "primary_passenger_id", nullable = false)
    public UUID primaryPassengerId;

    @Column(name = "booking_date")
    public Instant bookingDate;

    @Column(name = "status", nullable = false, length = 20)
    public String status;

    @Column(name = "total_amount", precision = 14, scale = 2)
    public BigDecimal totalAmount;

    @Column(name = "currency_code", length = 3)
    public String currencyCode;

    @PrePersist
    void onCreate() {
        if (bookingId == null) {
            bookingId = UUID.randomUUID();
        }
        if (bookingDate == null) {
            bookingDate = Instant.now();
        }
        if (currencyCode == null) {
            currencyCode = "IDR";
        }
    }

    public static Optional<Booking> findByReference(String reference) {
        return find("bookingReference", reference).firstResultOptional();
    }

    public static boolean referenceExists(String reference) {
        return count("bookingReference", reference) > 0;
    }
}
