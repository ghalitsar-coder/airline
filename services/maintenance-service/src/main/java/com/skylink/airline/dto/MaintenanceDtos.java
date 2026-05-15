package com.skylink.airline.dto;

import java.util.UUID;

public final class MaintenanceDtos {

    private MaintenanceDtos() {}

    public record MaintenanceView(
            UUID maintenanceId, UUID aircraftId, String maintenanceType, String status) {}

    public record CreateMaintenanceRequest(UUID aircraftId, String maintenanceType) {}

    public record StatusUpdateRequest(String status) {}

    public record ApproveRequest(String approvedBy, String notes) {}
}
