package com.skylink.airline.service;

import com.skylink.airline.dto.MaintenanceDtos.CreateMaintenanceRequest;
import com.skylink.airline.dto.MaintenanceDtos.MaintenanceView;
import com.skylink.airline.entity.MaintenanceRecord;
import com.skylink.airline.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class MaintenanceService {

    public List<MaintenanceView> listAll() {
        return MaintenanceRecord.<MaintenanceRecord>listAll().stream().map(this::toView).toList();
    }

    public MaintenanceView getById(UUID id) {
        return toView(requireRecord(id));
    }

    public List<MaintenanceView> historyByAircraft(UUID aircraftId) {
        return MaintenanceRecord.findByAircraftId(aircraftId).stream().map(this::toView).toList();
    }

    @Transactional
    public MaintenanceView create(CreateMaintenanceRequest request) {
        if (request.aircraftId() == null) {
            throw ApiException.badRequest("aircraftId is required");
        }
        MaintenanceRecord record = new MaintenanceRecord();
        record.maintenanceId = UUID.randomUUID();
        record.aircraftId = request.aircraftId();
        record.maintenanceType = request.maintenanceType();
        record.status = "REPORTED";
        record.persist();
        return toView(record);
    }

    @Transactional
    public MaintenanceView updateStatus(UUID id, String newStatus) {
        MaintenanceRecord record = requireRecord(id);
        MaintenanceStatusWorkflow.validateTransition(record.status, newStatus);
        record.status = MaintenanceStatusWorkflow.normalize(newStatus);
        record.persist();
        return toView(record);
    }

    @Transactional
    public MaintenanceView approve(UUID id) {
        MaintenanceRecord record = requireRecord(id);
        if (!MaintenanceStatusWorkflow.canApprove(record.status)) {
            throw ApiException.unprocessable("Record must be in ASSESSED status to approve");
        }
        record.status = "APPROVED";
        record.persist();
        return toView(record);
    }

    private MaintenanceRecord requireRecord(UUID id) {
        MaintenanceRecord record = MaintenanceRecord.findById(id);
        if (record == null) {
            throw ApiException.notFound("Maintenance record not found");
        }
        return record;
    }

    private MaintenanceView toView(MaintenanceRecord record) {
        return new MaintenanceView(
                record.maintenanceId,
                record.aircraftId,
                record.maintenanceType,
                MaintenanceStatusWorkflow.normalize(record.status));
    }
}
