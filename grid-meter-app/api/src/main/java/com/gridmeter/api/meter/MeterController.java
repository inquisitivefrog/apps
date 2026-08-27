package com.gridmeter.api.meter;

import com.gridmeter.api.auth.AuthenticatedUser;
import com.gridmeter.api.common.PageResponse;
import com.gridmeter.api.common.PaginationProperties;
import com.gridmeter.api.meter.dto.MeterRequest;
import com.gridmeter.api.meter.dto.MeterResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/meters")
public class MeterController {

    private final MeterService meterService;
    private final PaginationProperties paginationProperties;

    public MeterController(MeterService meterService, PaginationProperties paginationProperties) {
        this.meterService = meterService;
        this.paginationProperties = paginationProperties;
    }

    @PostMapping
    public ResponseEntity<MeterResponse> create(
            @Valid @RequestBody MeterRequest request, @AuthenticationPrincipal AuthenticatedUser principal) {
        Meter created = meterService.create(request, principal.customerId());
        return ResponseEntity.created(URI.create("/api/v1/meters/" + created.getId()))
                .body(MeterResponse.from(created));
    }

    @GetMapping
    public PageResponse<MeterResponse> search(
            @RequestParam(required = false) String location,
            @RequestParam(required = false) MeterStatus status,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        Pageable pageable = paginationProperties.toPageable(page, size, Sort.by("createdAt").descending());
        Page<Meter> result = meterService.search(location, status, pageable);
        return PageResponse.from(result.map(MeterResponse::from));
    }

    @GetMapping("/{id}")
    public MeterResponse findById(@PathVariable UUID id) {
        return MeterResponse.from(meterService.findById(id));
    }

    @PutMapping("/{id}")
    public MeterResponse update(@PathVariable UUID id, @Valid @RequestBody MeterRequest request) {
        return MeterResponse.from(meterService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        meterService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
