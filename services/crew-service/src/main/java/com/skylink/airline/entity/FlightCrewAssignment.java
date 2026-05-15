package com.skylink.airline.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "flight_crew_assignments")
public class FlightCrewAssignment extends PanacheEntityBase {

  private static final double HOURS_PER_ASSIGNMENT = 2.0;
  private static final double MAX_PILOT_HOURS = 8.0;

    @Id
    @Column(name = "assignment_id")
    public UUID assignmentId;

    @Column(name = "flight_id", nullable = false)
    public UUID flightId;

    @Column(name = "crew_id")
    public UUID crewId;

    @Column(name = "crew_role", nullable = false)
    public String crewRole;

    @Column(name = "is_confirmed", nullable = false)
    public boolean isConfirmed;

    public static List<FlightCrewAssignment> findByCrewId(UUID crewId) {
        return list("crewId", crewId);
    }

    public static List<FlightCrewAssignment> findByFlightId(UUID flightId) {
        return list("flightId", flightId);
    }

    public static long countPilotAssignments(UUID crewId) {
        return count(
                "crewId = ?1 and upper(crewRole) in ('CAPTAIN', 'FIRST_OFFICER')",
                crewId);
    }

    public static boolean wouldExceedPilotHours(UUID crewId, UUID excludeAssignmentId) {
        long count = FlightCrewAssignment.count(
                "crewId = ?1 and upper(crewRole) in ('CAPTAIN', 'FIRST_OFFICER') and assignmentId <> ?2",
                crewId,
                excludeAssignmentId);
        return (count + 1) * HOURS_PER_ASSIGNMENT > MAX_PILOT_HOURS;
    }

    public static boolean wouldExceedPilotHours(UUID crewId) {
        return countPilotAssignments(crewId) * HOURS_PER_ASSIGNMENT + HOURS_PER_ASSIGNMENT > MAX_PILOT_HOURS;
    }

    public static boolean isPilotRole(String role) {
        if (role == null) {
            return false;
        }
        String upper = role.toUpperCase();
        return "CAPTAIN".equals(upper) || "FIRST_OFFICER".equals(upper);
    }
}
