package com.skylink.airline.service;

import com.skylink.airline.dto.LoyaltyDtos.EarnRequest;
import com.skylink.airline.dto.LoyaltyDtos.LoyaltyAccountView;
import com.skylink.airline.dto.LoyaltyDtos.TierView;
import com.skylink.airline.dto.LoyaltyDtos.TransactionView;
import com.skylink.airline.entity.LoyaltyAccount;
import com.skylink.airline.entity.LoyaltyTransaction;
import com.skylink.airline.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class LoyaltyService {

    private static final List<TierView> TIERS =
            List.of(
                    new TierView("Blue", 0, 24_999, 1.0, "Standard benefits"),
                    new TierView("Silver", 25_000, 49_999, 1.25, "Priority check-in"),
                    new TierView("Gold", 50_000, 99_999, 1.5, "Lounge access"),
                    new TierView("Platinum", 100_000, Long.MAX_VALUE, 2.0, "Dedicated line and upgrades"));

    public List<TierView> listTiers() {
        return TIERS;
    }

    public LoyaltyAccountView getByPassengerId(UUID passengerId) {
        LoyaltyAccount account = requireAccount(passengerId);
        return toView(account);
    }

    public List<TransactionView> listTransactions(UUID passengerId) {
        LoyaltyAccount account = requireAccount(passengerId);
        return LoyaltyTransaction.findByLoyaltyId(account.loyaltyId).stream()
                .map(this::toTransactionView)
                .toList();
    }

    @Transactional
    public LoyaltyAccountView redeem(UUID passengerId, BigDecimal miles) {
        validatePositive(miles, "miles");
        LoyaltyAccount account = requireAccount(passengerId);
        if (account.availableMiles.compareTo(miles) < 0) {
            throw ApiException.unprocessable("Insufficient miles balance");
        }
        account.availableMiles = account.availableMiles.subtract(miles);
        account.persist();
        recordTransaction(account.loyaltyId, "REDEEM", miles.negate());
        return toView(account);
    }

    @Transactional
    public TransactionView reverseMiles(UUID passengerId, BigDecimal miles, String reason) {
        validatePositive(miles, "miles");
        if (reason == null || reason.isBlank()) {
            throw ApiException.badRequest("reason is required");
        }
        LoyaltyAccount account = requireAccount(passengerId);
        account.availableMiles = account.availableMiles.add(miles);
        account.persist();
        return toTransactionView(recordTransaction(account.loyaltyId, "REVERSE", miles));
    }

    @Transactional
    public LoyaltyAccountView earn(UUID passengerId, EarnRequest request) {
        LoyaltyAccount account = requireAccount(passengerId);
        BigDecimal miles = resolveEarnMiles(request, account);
        account.availableMiles = account.availableMiles.add(miles);
        account.persist();
        recordTransaction(account.loyaltyId, "EARN", miles);
        return toView(account);
    }

    private BigDecimal resolveEarnMiles(EarnRequest request, LoyaltyAccount account) {
        if (request.miles() != null && request.miles().compareTo(BigDecimal.ZERO) > 0) {
            return request.miles();
        }
        if (request.distanceKm() == null || request.distanceKm().compareTo(BigDecimal.ZERO) <= 0) {
            throw ApiException.badRequest("Provide miles or distanceKm with seatClass");
        }
        String seatClass = request.seatClass() == null ? "ECONOMY" : request.seatClass().toUpperCase();
        BigDecimal base = request.distanceKm();
        BigDecimal bonus = BigDecimal.ZERO;
        BigDecimal perKm = switch (seatClass) {
            case "ECONOMY_FLEX", "FLEX" -> new BigDecimal("1.3");
            case "BUSINESS" -> {
                bonus = new BigDecimal("500");
                yield new BigDecimal("1.5");
            }
            case "FIRST" -> {
                bonus = new BigDecimal("1000");
                yield new BigDecimal("2.0");
            }
            default -> BigDecimal.ONE;
        };
        double multiplier = tierMultiplier(account.tier);
        BigDecimal earned = base.multiply(perKm).add(bonus).multiply(BigDecimal.valueOf(multiplier));
        return earned.setScale(2, RoundingMode.HALF_UP);
    }

    private double tierMultiplier(String tier) {
        if (tier == null) {
            return 1.0;
        }
        return switch (tier.toUpperCase()) {
            case "SILVER" -> 1.25;
            case "GOLD" -> 1.5;
            case "PLATINUM" -> 2.0;
            default -> 1.0;
        };
    }

    private LoyaltyTransaction recordTransaction(UUID loyaltyId, String type, BigDecimal miles) {
        LoyaltyTransaction tx = new LoyaltyTransaction();
        tx.transactionId = UUID.randomUUID();
        tx.loyaltyId = loyaltyId;
        tx.transactionDate = OffsetDateTime.now();
        tx.transactionType = type;
        tx.milesAmount = miles;
        tx.persist();
        return tx;
    }

    private LoyaltyAccount requireAccount(UUID passengerId) {
        LoyaltyAccount account = LoyaltyAccount.findByPassengerId(passengerId);
        if (account == null) {
            throw ApiException.notFound("Loyalty account not found for passenger");
        }
        return account;
    }

    private void validatePositive(BigDecimal value, String field) {
        if (value == null || value.compareTo(BigDecimal.ZERO) <= 0) {
            throw ApiException.badRequest(field + " must be greater than zero");
        }
    }

    private LoyaltyAccountView toView(LoyaltyAccount account) {
        return new LoyaltyAccountView(
                account.loyaltyId,
                account.passengerId,
                account.membershipNumber,
                account.tier,
                mapDisplayTier(account.tier),
                account.availableMiles);
    }

    private String mapDisplayTier(String tier) {
        if (tier == null) {
            return "Blue";
        }
        return switch (tier.toUpperCase()) {
            case "SILVER" -> "Silver";
            case "GOLD" -> "Gold";
            case "PLATINUM" -> "Platinum";
            default -> "Blue";
        };
    }

    private TransactionView toTransactionView(LoyaltyTransaction tx) {
        return new TransactionView(
                tx.transactionId, tx.loyaltyId, tx.transactionDate, tx.transactionType, tx.milesAmount);
    }
}
