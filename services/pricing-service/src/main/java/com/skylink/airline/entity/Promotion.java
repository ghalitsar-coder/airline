package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "promotions")
public class Promotion extends PanacheEntityBase {

    @Id
    @Column(name = "promotion_id")
    public UUID promotionId;

    @Column(name = "promo_code", nullable = false, unique = true)
    public String promoCode;

    @Column(name = "discount_type", nullable = false)
    public String discountType;

    @Column(name = "discount_value", nullable = false)
    public BigDecimal discountValue;

    @Column(name = "valid_from", nullable = false)
    public Instant validFrom;

    @Column(name = "valid_until", nullable = false)
    public Instant validUntil;

    @Column(name = "is_active")
    public Boolean isActive;

    public static List<Promotion> findActive() {
        Instant now = Instant.now();
        return list(
                "isActive = true and validFrom <= ?1 and validUntil >= ?1",
                now);
    }

    public static Promotion findActiveByCode(String promoCode) {
        Instant now = Instant.now();
        return find(
                        "upper(promoCode) = ?1 and isActive = true and validFrom <= ?2 and validUntil >= ?2",
                        promoCode.toUpperCase(),
                        now)
                .firstResult();
    }
}
