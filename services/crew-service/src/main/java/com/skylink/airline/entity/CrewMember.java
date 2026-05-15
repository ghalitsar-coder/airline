package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "crew_members")
public class CrewMember extends PanacheEntityBase {

    @Id
    @Column(name = "crew_id")
    public UUID crewId;

    @Column(name = "employee_id", unique = true)
    public UUID employeeId;

    @Column(name = "crew_role", nullable = false)
    public String crewRole;

    @Column(name = "license_number")
    public String licenseNumber;

    public static CrewMember findByCrewId(UUID crewId) {
        return findById(crewId);
    }

    public static List<CrewMember> findAllCrew() {
        return listAll();
    }
}
