package com.skylink.airline.service;

import com.skylink.airline.dto.CrewDtos.AssignmentView;
import com.skylink.airline.dto.CrewDtos.CreateAssignmentRequest;
import com.skylink.airline.dto.CrewDtos.CrewMemberView;
import com.skylink.airline.dto.CrewDtos.UpdateAssignmentRequest;
import com.skylink.airline.entity.CrewMember;
import com.skylink.airline.entity.Employee;
import com.skylink.airline.entity.FlightCrewAssignment;
import com.skylink.airline.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class CrewService {

    public List<CrewMemberView> listCrew() {
        return CrewMember.findAllCrew().stream().map(this::toCrewView).toList();
    }

    public CrewMemberView getCrew(UUID crewId) {
        return toCrewView(requireCrew(crewId));
    }

    public List<AssignmentView> getSchedule(UUID crewId) {
        requireCrew(crewId);
        return FlightCrewAssignment.findByCrewId(crewId).stream()
                .map(this::toAssignmentView)
                .toList();
    }

    public List<AssignmentView> getFlightCrew(UUID flightId) {
        return FlightCrewAssignment.findByFlightId(flightId).stream()
                .map(this::toAssignmentView)
                .toList();
    }

    @Transactional
    public AssignmentView createAssignment(CreateAssignmentRequest request) {
        validateAssignmentRequest(request.flightId(), request.crewId(), request.crewRole());
        CrewMember crew = requireCrew(request.crewId());
        String role = request.crewRole().toUpperCase();
        validatePilotHours(crew.crewId, role, null);
        FlightCrewAssignment assignment = new FlightCrewAssignment();
        assignment.assignmentId = UUID.randomUUID();
        assignment.flightId = request.flightId();
        assignment.crewId = request.crewId();
        assignment.crewRole = role;
        assignment.isConfirmed = request.isConfirmed() != null && request.isConfirmed();
        assignment.persist();
        return toAssignmentView(assignment);
    }

    @Transactional
    public AssignmentView updateAssignment(UUID assignmentId, UpdateAssignmentRequest request) {
        FlightCrewAssignment assignment = requireAssignment(assignmentId);
        UUID crewId = request.crewId() != null ? request.crewId() : assignment.crewId;
        String role = request.crewRole() != null ? request.crewRole().toUpperCase() : assignment.crewRole;
        UUID flightId = request.flightId() != null ? request.flightId() : assignment.flightId;
        if (request.crewId() == null && request.crewRole() == null && request.flightId() == null
                && request.isConfirmed() == null) {
            throw ApiException.badRequest("No fields to update");
        }
        requireCrew(crewId);
        validatePilotHours(crewId, role, assignmentId);
        assignment.flightId = flightId;
        assignment.crewId = crewId;
        assignment.crewRole = role;
        if (request.isConfirmed() != null) {
            assignment.isConfirmed = request.isConfirmed();
        }
        assignment.persist();
        return toAssignmentView(assignment);
    }

    private void validateAssignmentRequest(UUID flightId, UUID crewId, String crewRole) {
        if (flightId == null || crewId == null || crewRole == null || crewRole.isBlank()) {
            throw ApiException.badRequest("flightId, crewId, and crewRole are required");
        }
    }

    private void validatePilotHours(UUID crewId, String role, UUID excludeAssignmentId) {
        if (!FlightCrewAssignment.isPilotRole(role)) {
            return;
        }
        boolean exceeded = excludeAssignmentId == null
                ? FlightCrewAssignment.wouldExceedPilotHours(crewId)
                : FlightCrewAssignment.wouldExceedPilotHours(crewId, excludeAssignmentId);
        if (exceeded) {
            throw ApiException.unprocessable(
                    "DGCA limit: pilot cannot exceed 8 flight hours (simplified duty check)");
        }
    }

    private CrewMember requireCrew(UUID crewId) {
        CrewMember crew = CrewMember.findByCrewId(crewId);
        if (crew == null) {
            throw ApiException.notFound("Crew member not found");
        }
        return crew;
    }

    private FlightCrewAssignment requireAssignment(UUID assignmentId) {
        FlightCrewAssignment assignment = FlightCrewAssignment.findById(assignmentId);
        if (assignment == null) {
            throw ApiException.notFound("Assignment not found");
        }
        return assignment;
    }

    private CrewMemberView toCrewView(CrewMember crew) {
        Employee employee = Employee.findByEmployeeId(crew.employeeId);
        if (employee == null) {
            throw ApiException.notFound("Employee record not found for crew member");
        }
        return new CrewMemberView(
                crew.crewId,
                crew.employeeId,
                employee.employeeNumber,
                employee.firstName,
                employee.lastName,
                employee.email,
                crew.crewRole,
                crew.licenseNumber);
    }

    private AssignmentView toAssignmentView(FlightCrewAssignment assignment) {
        return new AssignmentView(
                assignment.assignmentId,
                assignment.flightId,
                assignment.crewId,
                assignment.crewRole,
                assignment.isConfirmed);
    }
}
