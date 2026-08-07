package com.example.houseprice.controller;

import com.example.houseprice.service.PricePredictionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class PricePredictionControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PricePredictionService service;

    @Test
    public void testPredictValidInput() throws Exception {
        double expected = Math.round(service.predict(1800.75, 3) * 100.0) / 100.0;
        mockMvc.perform(get("/predict")
                .param("size", "1800.75")
                .param("bedrooms", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.predictedPrice").value(expected));
    }

    @Test
    public void testPredictInvalidInputSize() throws Exception {
        mockMvc.perform(get("/predict")
                .param("size", "-100")
                .param("bedrooms", "3"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid size or bedrooms"));
    }

    @Test
    public void testPredictInvalidInputBedrooms() throws Exception {
        mockMvc.perform(get("/predict")
                .param("size", "3000")
                .param("bedrooms", "-2"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid size or bedrooms"));
    }

    @Test
    public void testGetRmse() throws Exception {
        double expected = service.getRmse();
        mockMvc.perform(get("/rmse"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rmse").value(expected));
    }
}
