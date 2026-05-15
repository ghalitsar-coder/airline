package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.time.Instant;

public record CreatePromotionRequest(
        @JsonProperty("promo_code") String promoCode,
        @JsonProperty("discount_type") String discountType,
        @JsonProperty("discount_value") BigDecimal discountValue,
        @JsonProperty("valid_from") Instant validFrom,
        @JsonProperty("valid_until") Instant validUntil,
        @JsonProperty("is_active") Boolean isActive) {}
