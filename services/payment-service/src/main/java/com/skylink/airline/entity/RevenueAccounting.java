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
@Table(name = "revenue_accounting")
public class RevenueAccounting extends PanacheEntityBase {

    @Id
    @Column(name = "revenue_id")
    public UUID revenueId;

    @Column(name = "booking_id", nullable = false)
    public UUID bookingId;

    @Column(name = "flight_id", nullable = false)
    public UUID flightId;

    @Column(name = "revenue_type", nullable = false, length = 50)
    public String revenueType;

    @Column(name = "gross_amount", nullable = false, precision = 14, scale = 2)
    public BigDecimal grossAmount;

    @Column(name = "tax_amount", nullable = false, precision = 12, scale = 2)
    public BigDecimal taxAmount = BigDecimal.ZERO;

    @Column(name = "currency_code", length = 3)
    public String currencyCode;

    @PrePersist
    void assignId() {
        if (revenueId == null) {
            revenueId = UUID.randomUUID();
        }
    }
}
