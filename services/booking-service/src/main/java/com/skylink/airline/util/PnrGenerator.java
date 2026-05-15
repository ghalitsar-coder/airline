package com.skylink.airline.util;

import com.skylink.airline.entity.Booking;

import java.security.SecureRandom;

public final class PnrGenerator {

    private static final SecureRandom RANDOM = new SecureRandom();

    private PnrGenerator() {}

    public static String generateUnique() {
        for (int attempt = 0; attempt < 50; attempt++) {
            String pnr = "NA" + String.format("%04d", RANDOM.nextInt(10_000));
            if (!Booking.referenceExists(pnr)) {
                return pnr;
            }
        }
        throw new IllegalStateException("Unable to generate unique PNR");
    }
}
