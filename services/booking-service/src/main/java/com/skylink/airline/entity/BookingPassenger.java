package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "booking_passengers")
public class BookingPassenger extends PanacheEntityBase {

    @Id
    @Column(name = "booking_passenger_id")
    public UUID bookingPassengerId;

    @Column(name = "booking_id")
    public UUID bookingId;

    @Column(name = "passenger_id", nullable = false)
    public UUID passengerId;

    @Column(name = "passenger_type", nullable = false, length = 20)
    public String passengerType;

    @Column(name = "first_name", length = 100)
    public String firstName;

    @Column(name = "last_name", length = 100)
    public String lastName;

    @PrePersist
    void onCreate() {
        if (bookingPassengerId == null) {
            bookingPassengerId = UUID.randomUUID();
        }
    }

    public static List<BookingPassenger> listByBooking(UUID bookingId) {
        return list("bookingId", bookingId);
    }
}
