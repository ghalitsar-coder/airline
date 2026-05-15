package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "loyalty_transactions")
public class LoyaltyTransaction extends PanacheEntityBase {

    @Id
    @Column(name = "transaction_id")
    public UUID transactionId;

    @Column(name = "loyalty_id")
    public UUID loyaltyId;

    @Column(name = "transaction_date", nullable = false)
    public OffsetDateTime transactionDate;

    @Column(name = "transaction_type", nullable = false)
    public String transactionType;

    @Column(name = "miles_amount", nullable = false)
    public BigDecimal milesAmount;

    public static List<LoyaltyTransaction> findByLoyaltyId(UUID loyaltyId) {
        return list("loyaltyId = ?1 order by transactionDate desc", loyaltyId);
    }
}
