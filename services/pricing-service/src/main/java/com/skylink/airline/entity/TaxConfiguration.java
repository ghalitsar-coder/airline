package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "tax_configurations")
public class TaxConfiguration extends PanacheEntityBase {

    @Id
    @Column(name = "tax_id")
    public UUID taxId;

    @Column(name = "tax_name", nullable = false)
    public String taxName;

    @Column(name = "tax_percentage", nullable = false)
    public BigDecimal taxPercentage;

    @Column(name = "is_active")
    public Boolean isActive;

    public static List<TaxConfiguration> findActive() {
        return list("isActive", true);
    }
}
