package com.skylink.airline.service;

import com.skylink.airline.exception.ApiException;
import java.util.Map;
import java.util.Set;

public final class MaintenanceStatusWorkflow {

    private static final Map<String, Set<String>> TRANSITIONS =
            Map.of(
                    "REPORTED", Set.of("ASSESSED"),
                    "ASSESSED", Set.of("APPROVED", "REJECTED", "AOG_HOLD"),
                    "APPROVED", Set.of("IN_PROGRESS", "AOG_HOLD"),
                    "IN_PROGRESS", Set.of("QA_CHECK", "AOG_HOLD"),
                    "QA_CHECK", Set.of("COMPLETED", "IN_PROGRESS"),
                    "COMPLETED", Set.of("CERTIFIED"),
                    "AOG_HOLD", Set.of("ASSESSED", "APPROVED"),
                    "REJECTED", Set.of(),
                    "CERTIFIED", Set.of(),
                    "PLANNED", Set.of("REPORTED", "ASSESSED", "IN_PROGRESS"));

    private MaintenanceStatusWorkflow() {}

    public static String normalize(String status) {
        return status == null ? null : status.trim().toUpperCase();
    }

    public static void validateTransition(String current, String next) {
        String from = normalize(current);
        String to = normalize(next);
        if (from == null || to == null) {
            throw ApiException.badRequest("status is required");
        }
        if (from.equals(to)) {
            return;
        }
        Set<String> allowed = TRANSITIONS.get(from);
        if (allowed == null || !allowed.contains(to)) {
            throw ApiException.unprocessable("Invalid status transition from " + from + " to " + to);
        }
    }

    public static boolean canApprove(String status) {
        return "ASSESSED".equals(normalize(status));
    }
}
