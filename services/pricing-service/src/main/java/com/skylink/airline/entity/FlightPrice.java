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
@Table(name = "flight_prices")
public class FlightPrice extends PanacheEntityBase {

    @Id
    @Column(name = "price_id")
    public UUID priceId;

    @Column(name = "flight_id", nullable = false)
    public UUID flightId;

    @Column(name = "seat_class", nullable = false)
    public String seatClass;

    @Column(name = "fare_basis", nullable = false)
    public String fareBasis;

    @Column(name = "base_price", nullable = false)
    public BigDecimal basePrice;

    @Column(name = "tax_amount", nullable = false)
    public BigDecimal taxAmount;

    @Column(name = "currency_code", columnDefinition = "CHAR(3)")
    public String currencyCode;

    @Column(name = "valid_from", nullable = false)
    public Instant validFrom;

    @Column(name = "valid_until")
    public Instant validUntil;

    public static List<FlightPrice> findByFlightId(UUID flightId) {
        return list("flightId", flightId);
    }

    public static List<FlightPrice> findAllActive() {
        return list("validUntil is null or validUntil > ?1", Instant.now());
    }

    public static FlightPrice findBestForFlightAndClass(UUID flightId, String seatClass) {
        FlightPrice exact = find(
                "flightId = ?1 and upper(seatClass) = ?2 and (validUntil is null or validUntil > ?3)",
                flightId,
                seatClass.toUpperCase(),
                Instant.now())
                .firstResult();
        if (exact != null) {
            return exact;
        }
        return find(
                        "flightId = ?1 and (validUntil is null or validUntil > ?2) order by basePrice asc",
                        flightId,
                        Instant.now())
                .firstResult();
    }
}
