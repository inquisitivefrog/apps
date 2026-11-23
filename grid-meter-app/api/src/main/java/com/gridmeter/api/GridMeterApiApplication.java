package com.gridmeter.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.resilience.annotation.EnableResilientMethods;
import org.springframework.scheduling.annotation.EnableScheduling;

// @EnableResilientMethods backs ReadingService.ingest()'s @Retryable -- see its own comment for
// why (a transient Postgres blip shouldn't have to surface as a hard failure). Spring Framework
// 7's own native resilience annotations, not the older spring-retry library -- no extra
// dependency needed, spring-context (already required regardless) is all this takes.
//
// @EnableScheduling backs ActiveUserTracker.refresh() -- see its class comment for why the
// active-users gauge is refreshed in the background instead of querying Redis on each scrape.
@EnableResilientMethods
@EnableScheduling
@SpringBootApplication
public class GridMeterApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(GridMeterApiApplication.class, args);
    }
}
