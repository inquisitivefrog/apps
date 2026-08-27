package com.gridmeter.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.retry.annotation.EnableRetry;

// @EnableRetry backs ReadingService.ingest()'s @Retryable -- see its own comment for why
// (a transient Postgres blip shouldn't have to surface as a hard failure).
@EnableRetry
@SpringBootApplication
public class GridMeterApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(GridMeterApiApplication.class, args);
    }
}
