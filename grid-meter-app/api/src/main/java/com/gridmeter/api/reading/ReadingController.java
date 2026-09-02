package com.gridmeter.api.reading;

import com.gridmeter.api.common.PageResponse;
import com.gridmeter.api.common.PaginationProperties;
import com.gridmeter.api.reading.dto.ReadingRequest;
import com.gridmeter.api.reading.dto.ReadingResponse;
import jakarta.validation.Valid;
import java.math.BigDecimal;
import java.net.URI;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** No PUT endpoint here — readings are immutable events; corrections are new readings, not edits. */
@RestController
@RequestMapping("/api/v1/readings")
public class ReadingController {

    private final ReadingService readingService;
    private final PaginationProperties paginationProperties;

    public ReadingController(ReadingService readingService, PaginationProperties paginationProperties) {
        this.readingService = readingService;
        this.paginationProperties = paginationProperties;
    }

    // docs/idempotency-scope.md: required, not optional -- an optional header would just
    // reintroduce the exact ambiguity this feature exists to close for any client that doesn't
    // bother sending it. Spring's default MissingRequestHeaderException handling covers the
    // rejection itself; GlobalExceptionHandler maps it to this API's own ApiError shape.
    @PostMapping
    public ResponseEntity<ReadingResponse> ingest(
            @Valid @RequestBody ReadingRequest request,
            @RequestHeader("Idempotency-Key") String idempotencyKey) {
        ReadingEvent event = readingService.ingest(request, idempotencyKey);
        return ResponseEntity.created(URI.create("/api/v1/readings/" + event.id()))
                .body(ReadingResponse.from(event));
    }

    @GetMapping
    public PageResponse<ReadingResponse> search(
            @RequestParam(required = false) UUID meterId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false) BigDecimal minValue,
            @RequestParam(required = false) BigDecimal maxValue,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        Pageable pageable = paginationProperties.toPageable(page, size, Sort.by("readingTimestamp").descending());
        Page<Reading> result = readingService.search(meterId, from, to, minValue, maxValue, pageable);
        return PageResponse.from(result.map(ReadingResponse::from));
    }

    @GetMapping("/{id}")
    public ReadingResponse findById(@PathVariable UUID id) {
        return ReadingResponse.from(readingService.findById(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        readingService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
