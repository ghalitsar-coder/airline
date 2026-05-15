package com.skylink.airline.dto;

import com.skylink.airline.entity.Promotion;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record PromotionDto(
        UUID promotionId,
        String promoCode,
        String discountType,
        BigDecimal discountValue,
        Instant validFrom,
        Instant validUntil,
        Boolean isActive) {

    public static PromotionDto from(Promotion entity) {
        return new PromotionDto(
                entity.promotionId,
                entity.promoCode,
                entity.discountType,
                entity.discountValue,
                entity.validFrom,
                entity.validUntil,
                entity.isActive);
    }
}
