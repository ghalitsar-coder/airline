package com.skylink.airline.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public final class LoyaltyDtos {

    private LoyaltyDtos() {}

    public record LoyaltyAccountView(
            UUID loyaltyId,
            UUID passengerId,
            String membershipNumber,
            String tier,
            String displayTier,
            BigDecimal availableMiles) {}

    public record TransactionView(
            UUID transactionId,
            UUID loyaltyId,
            OffsetDateTime transactionDate,
            String transactionType,
            BigDecimal milesAmount) {}

    public record RedeemRequest(BigDecimal miles) {}

    public record ReverseMilesRequest(BigDecimal miles, String reason) {}

    public record EarnRequest(BigDecimal miles, String seatClass, BigDecimal distanceKm) {}

    public record TierView(
            String name,
            long milesPerYearMin,
            long milesPerYearMax,
            double earnMultiplier,
            String benefit) {}
}
