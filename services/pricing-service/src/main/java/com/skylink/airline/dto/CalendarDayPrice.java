package com.skylink.airline.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.time.LocalDate;

public record CalendarDayPrice(
        LocalDate date,
        @JsonProperty("lowest_base_price") BigDecimal lowestBasePrice,
        @JsonProperty("currency_code") String currencyCode) {}
