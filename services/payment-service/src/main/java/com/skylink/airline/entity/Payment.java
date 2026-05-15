package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "payments")
public class Payment extends PanacheEntityBase {

    @Id
    @Column(name = "payment_id")
    public UUID paymentId;

    @Column(name = "booking_id", nullable = false)
    public UUID bookingId;

    @Column(name = "payment_method", length = 30)
    public String paymentMethod;

    @Column(name = "payment_status", nullable = false, length = 30)
    public String paymentStatus = "PENDING";

    @Column(name = "amount", precision = 14, scale = 2)
    public BigDecimal amount;

    @Column(name = "currency_code", length = 3)
    public String currencyCode = "IDR";

    @PrePersist
    void assignId() {
        if (paymentId == null) {
            paymentId = UUID.randomUUID();
        }
    }
}
