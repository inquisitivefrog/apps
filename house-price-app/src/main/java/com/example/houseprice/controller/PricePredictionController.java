package com.example.houseprice.controller;

import com.example.houseprice.service.PricePredictionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PricePredictionController {
    @Autowired
    private PricePredictionService service;

    @GetMapping("/predict")
    public ResponseEntity<?> predictPrice(@RequestParam double size, @RequestParam int bedrooms) {
        try {
            double prediction = service.predict(size, bedrooms);
            return ResponseEntity.ok(new PredictionResponse(prediction));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @GetMapping("/rmse")
    public ResponseEntity<?> getRmse() {
        return ResponseEntity.ok(new RmseResponse(service.getRmse()));
    }

    public static class PredictionResponse {
        private final double predictedPrice;

        public PredictionResponse(double predictedPrice) {
            this.predictedPrice = predictedPrice;
        }

        public double getPredictedPrice() {
            return Math.round(predictedPrice * 100.0) / 100.0;
        }
    }

    public static class ErrorResponse {
        private final String error;

        public ErrorResponse(String error) {
            this.error = error;
        }

        public String getError() {
            return error;
        }
    }

    public static class RmseResponse {
        private final double rmse;

        public RmseResponse(double rmse) {
            this.rmse = rmse;
        }

        public double getRmse() {
            return rmse;
        }
    }
}
