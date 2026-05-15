package com.skylink.airline.resource;

import io.quarkus.test.junit.QuarkusTest;
import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import org.junit.jupiter.api.Test;

@QuarkusTest
class HealthResourceTest {

    @Test
    void healthReturnsUp() {
        given()
                .when()
                .get("/health")
                .then()
                .statusCode(200)
                .body("status", is("UP"))
                .body("service", is("payment-service"));
    }
}
