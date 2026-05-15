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
@Table(name = "baggage")
public class Baggage extends PanacheEntityBase {

    @Id
    @Column(name = "baggage_id")
    public UUID baggageId;

    @Column(name = "segment_id")
    public UUID segmentId;

    @Column(name = "tag_number", nullable = false, unique = true, length = 20)
    public String tagNumber;

    @Column(name = "weight_kg", nullable = false, precision = 6, scale = 2)
    public BigDecimal weightKg;

    @Column(name = "baggage_type", nullable = false, length = 30)
    public String baggageType;

    @Column(name = "status", nullable = false, length = 30)
    public String status;

    @PrePersist
    void onCreate() {
        if (baggageId == null) {
            baggageId = UUID.randomUUID();
        }
        if (status == null) {
            status = "CHECKED_IN";
        }
    }
}
