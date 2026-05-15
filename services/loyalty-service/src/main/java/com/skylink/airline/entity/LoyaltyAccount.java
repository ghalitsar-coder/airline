package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "loyalty_accounts")
public class LoyaltyAccount extends PanacheEntityBase {

    @Id
    @Column(name = "loyalty_id")
    public UUID loyaltyId;

    @Column(name = "passenger_id", nullable = false)
    public UUID passengerId;

    @Column(name = "membership_number", nullable = false, unique = true)
    public String membershipNumber;

    @Column(name = "tier", nullable = false)
    public String tier;

    @Column(name = "available_miles")
    public BigDecimal availableMiles;

    public static LoyaltyAccount findByPassengerId(UUID passengerId) {
        return find("passengerId", passengerId).firstResult();
    }
}
