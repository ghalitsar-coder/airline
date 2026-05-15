package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Entity
@Table(name = "check_ins")
public class CheckIn extends PanacheEntityBase {

    @Id
    @Column(name = "check_in_id")
    public UUID checkInId;

    @Column(name = "segment_id", nullable = false, unique = true)
    public UUID segmentId;

    @Column(name = "check_in_method", nullable = false, length = 20)
    public String checkInMethod;

    @Column(name = "checked_in_at", nullable = false)
    public Instant checkedInAt;

    @Column(name = "boarding_pass_issued", nullable = false)
    public boolean boardingPassIssued;

    @PrePersist
    void onCreate() {
        if (checkInId == null) {
            checkInId = UUID.randomUUID();
        }
        if (checkedInAt == null) {
            checkedInAt = Instant.now();
        }
    }

    public static Optional<CheckIn> findBySegment(UUID segmentId) {
        return find("segmentId", segmentId).firstResultOptional();
    }
}
