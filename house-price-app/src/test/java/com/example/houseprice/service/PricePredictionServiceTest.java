package com.example.houseprice.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class PricePredictionServiceTest {
    @Autowired
    private PricePredictionService service;

    @Test
    public void testPredictValidInput() {
        double prediction = service.predict(1800.75, 3);
        assertTrue(prediction > 0, "Prediction should be positive");
        assertEquals(273977.51, prediction, 0.01, "Prediction should match expected value");
        System.out.println("Predicted price: " + prediction);
    }

    @Test
    public void testPredictInvalidInput() {
        Exception exception = assertThrows(IllegalArgumentException.class, () -> {
            service.predict(-100, 3);
        });
        assertEquals("Invalid size or bedrooms", exception.getMessage());
    }

    @Test
    public void testGetRmse() {
        double rmse = service.getRmse();
        assertTrue(rmse > 0, "RMSE should be positive");
        assertEquals(14445.52, rmse, 0.01, "RMSE should match expected value");
        System.out.println("RMSE: " + rmse);
    }
}
