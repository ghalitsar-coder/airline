package com.skylink.airline.dto;

import java.util.UUID;

public final class CrewDtos {

    private CrewDtos() {}

    public record CrewMemberView(
            UUID crewId,
            UUID employeeId,
            String employeeNumber,
            String firstName,
            String lastName,
            String email,
            String crewRole,
            String licenseNumber) {}

    public record AssignmentView(
            UUID assignmentId,
            UUID flightId,
            UUID crewId,
            String crewRole,
            boolean confirmed) {}

    public record CreateAssignmentRequest(
            UUID flightId, UUID crewId, String crewRole, Boolean isConfirmed) {}

    public record UpdateAssignmentRequest(
            UUID flightId, UUID crewId, String crewRole, Boolean isConfirmed) {}
}
