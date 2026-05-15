package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Entity
@Table(name = "booking_segments")
public class BookingSegment extends PanacheEntityBase {

    @Id
    @Column(name = "segment_id")
    public UUID segmentId;

    @Column(name = "booking_id")
    public UUID bookingId;

    @Column(name = "booking_passenger_id")
    public UUID bookingPassengerId;

    @Column(name = "flight_id", nullable = false)
    public UUID flightId;

    @Column(name = "price_id")
    public UUID priceId;

    @Column(name = "seat_id")
    public UUID seatId;

    @Column(name = "seat_class", length = 20)
    public String seatClass;

    @Column(name = "status", length = 20)
    public String status;

    @PrePersist
    void onCreate() {
        if (segmentId == null) {
            segmentId = UUID.randomUUID();
        }
        if (status == null) {
            status = "PENDING";
        }
    }

    public static List<BookingSegment> listByBooking(UUID bookingId) {
        return list("bookingId", bookingId);
    }

    public static Optional<BookingSegment> findByIdAndBooking(UUID segmentId, UUID bookingId) {
        return find("segmentId = ?1 and bookingId = ?2", segmentId, bookingId).firstResultOptional();
    }
}
