package com.gridmeter.api.meter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.customer.Customer;
import com.gridmeter.api.customer.CustomerRepository;
import com.gridmeter.api.meter.dto.MeterRequest;
import com.gridmeter.api.support.ComponentTestSupport;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

/** Component tests for {@link MeterService} against a real Postgres (see ComponentTestSupport). */
class MeterComponentTest extends ComponentTestSupport {

    @Autowired
    private MeterService meterService;

    @Autowired
    private CustomerRepository customerRepository;

    private MeterRequest randomRequest(String location, MeterStatus status) {
        return new MeterRequest(
                "MTR-" + UUID.randomUUID(), location, status, Instant.parse("2026-01-15T00:00:00Z"));
    }

    private Meter create(MeterRequest request) {
        return meterService.create(request, Customer.DEFAULT_ID);
    }

    private UUID createOtherCustomer() {
        Instant now = Instant.now();
        return customerRepository.save(Customer.builder()
                .id(UUID.randomUUID())
                .name("Other Customer " + UUID.randomUUID())
                .createdAt(now)
                .updatedAt(now)
                .build()).getId();
    }

    @Test
    void create_persistsAndReturnsMeter() {
        Meter created = create(randomRequest("123 Main St", MeterStatus.ACTIVE));

        assertThat(created.getId()).isNotNull();
        assertThat(created.getCreatedAt()).isNotNull();
        assertThat(created.getUpdatedAt()).isEqualTo(created.getCreatedAt());
        assertThat(meterService.findById(created.getId()).getSerialNumber())
                .isEqualTo(created.getSerialNumber());
    }

    @Test
    void create_duplicateSerialNumber_violatesUniqueConstraint() {
        Meter created = create(randomRequest("123 Main St", MeterStatus.ACTIVE));
        MeterRequest duplicate = new MeterRequest(
                created.getSerialNumber(), "456 Other St", MeterStatus.ACTIVE, Instant.now());

        assertThatThrownBy(() -> create(duplicate))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void findById_unknownId_throwsNotFound() {
        assertThatThrownBy(() -> meterService.findById(UUID.randomUUID()))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void search_filtersByLocationAndStatus() {
        String location = "Search Test Ave " + UUID.randomUUID();
        Meter active = create(randomRequest(location, MeterStatus.ACTIVE));
        create(randomRequest(location, MeterStatus.MAINTENANCE));

        Page<Meter> result = meterService.search(
                location, MeterStatus.ACTIVE, PageRequest.of(0, 20, Sort.by("createdAt").descending()));

        assertThat(result.getContent()).extracting(Meter::getId).containsExactly(active.getId());
    }

    // docs/multi-tenancy-scope.md, "Testing implications": this pass adds customerId but
    // deliberately does NOT enforce tenant isolation -- documents that as a real, tested behavior
    // (not an assumption) so a future isolation change has to touch this test deliberately rather
    // than silently regressing (or silently failing to add) isolation in either direction.
    @Test
    void search_returnsMetersAcrossAllCustomers_documentingCurrentNonIsolation() {
        String location = "Cross-Tenant Search Test " + UUID.randomUUID();
        UUID otherCustomerId = createOtherCustomer();
        Meter defaultCustomerMeter = create(randomRequest(location, MeterStatus.ACTIVE));
        Meter otherCustomerMeter = meterService.create(randomRequest(location, MeterStatus.ACTIVE), otherCustomerId);

        Page<Meter> result = meterService.search(
                location, MeterStatus.ACTIVE, PageRequest.of(0, 20, Sort.by("createdAt").descending()));

        assertThat(result.getContent())
                .extracting(Meter::getId)
                .containsExactlyInAnyOrder(defaultCustomerMeter.getId(), otherCustomerMeter.getId());
        assertThat(result.getContent())
                .extracting(Meter::getCustomerId)
                .containsExactlyInAnyOrder(Customer.DEFAULT_ID, otherCustomerId);
    }

    @Test
    void update_changesFieldsAndBumpsUpdatedAt() {
        Meter created = create(randomRequest("Original Location", MeterStatus.ACTIVE));
        MeterRequest updateRequest = new MeterRequest(
                created.getSerialNumber(), "New Location", MeterStatus.INACTIVE, created.getInstalledAt());

        Meter updated = meterService.update(created.getId(), updateRequest);

        assertThat(updated.getLocation()).isEqualTo("New Location");
        assertThat(updated.getStatus()).isEqualTo(MeterStatus.INACTIVE);
        assertThat(updated.getUpdatedAt()).isAfterOrEqualTo(created.getUpdatedAt());
    }

    @Test
    void update_unknownId_throwsNotFound() {
        MeterRequest request = randomRequest("Nowhere", MeterStatus.ACTIVE);
        assertThatThrownBy(() -> meterService.update(UUID.randomUUID(), request))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void delete_removesMeter() {
        Meter created = create(randomRequest("Delete Me Rd", MeterStatus.ACTIVE));

        meterService.delete(created.getId());

        assertThatThrownBy(() -> meterService.findById(created.getId()))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void delete_unknownId_throwsNotFound() {
        assertThatThrownBy(() -> meterService.delete(UUID.randomUUID()))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
