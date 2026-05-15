package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "maintenance_records")
public class MaintenanceRecord extends PanacheEntityBase {

    @Id
    @Column(name = "maintenance_id")
    public UUID maintenanceId;

    @Column(name = "aircraft_id", nullable = false)
    public UUID aircraftId;

    @Column(name = "maintenance_type")
    public String maintenanceType;

    @Column(name = "status")
    public String status;

    public static List<MaintenanceRecord> findByAircraftId(UUID aircraftId) {
        return list("aircraftId = ?1 order by maintenanceId desc", aircraftId);
    }
}
