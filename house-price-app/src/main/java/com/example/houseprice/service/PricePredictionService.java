package com.example.houseprice.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import smile.data.DataFrame;
import smile.data.formula.Formula;
import smile.data.vector.DoubleVector;
import smile.regression.OLS;
import smile.regression.LinearModel;
import smile.validation.CrossValidation;
import smile.validation.RegressionValidations;
import smile.validation.RegressionValidation;
import smile.validation.metric.RMSE;

import java.util.Arrays;

@Service
public class PricePredictionService {
    private static final Logger logger = LoggerFactory.getLogger(PricePredictionService.class);
    private LinearModel model;
    private String[] featureNames = {"size", "bedrooms"};
    private double rmse; // Declare rmse as a class field

    public PricePredictionService() {
        // Simulated dataset: [size (sqft), bedrooms] -> price (USD)
        double[][] X = {
            {1400, 3}, {1600, 3}, {1700, 4}, {1875, 3}, {1100, 2},
            {1550, 3}, {2350, 4}, {2450, 5}, {1425, 3}, {1700, 3}
        };
        double[] y = {
            200000, 250000, 270000, 300000, 150000,
            240000, 350000, 400000, 220000, 260000
        };

        // Convert to Smile DataFrame
        DataFrame features = DataFrame.of(X, featureNames);
        DoubleVector target = DoubleVector.of("price", y);
        DataFrame df = features.merge(target);

        // Train the linear regression model
        model = OLS.fit(Formula.lhs("price"), df);

        // Calculate RMSE using 5-fold cross-validation
        RegressionValidations<LinearModel> cv = CrossValidation.regression(5, Formula.lhs("price"), df,
            (formula, data) -> OLS.fit(formula, data));
        double[] rmseValues = new double[cv.rounds.size()];
        for (int i = 0; i < cv.rounds.size(); i++) {
            RegressionValidation<LinearModel> validation = cv.rounds.get(i);
            rmseValues[i] = RMSE.of(validation.truth, validation.prediction);
        }
        rmse = Arrays.stream(rmseValues).average().orElse(Double.NaN); // Assign to class field
        logger.info("RMSE: {}", rmse);
    }

    public double getRmse() {
        return Math.round(rmse * 100.0) / 100.0;
    }

    public double predict(double size, int bedrooms) {
        logger.info("Predicting for size={}, bedrooms={}", size, bedrooms);
        if (size <= 0 || size > 10000 || bedrooms <= 0 || bedrooms > 20) {
            logger.error("Invalid input: size={}, bedrooms={}", size, bedrooms);
            throw new IllegalArgumentException("Invalid size or bedrooms");
        }
        double[][] input = {{size, bedrooms}};
        DataFrame inputDf = DataFrame.of(input, featureNames);
        double prediction = model.predict(inputDf)[0];
        logger.info("Prediction: {}", prediction);
        return prediction;
    }
}
