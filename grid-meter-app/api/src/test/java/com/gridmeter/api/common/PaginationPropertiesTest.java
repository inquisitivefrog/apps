package com.gridmeter.api.common;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

/** Pure unit test — no Spring context needed, just the default/max-size clamping logic. */
class PaginationPropertiesTest {

    private static final Sort SORT = Sort.by("createdAt").descending();

    private PaginationProperties properties() {
        return new PaginationProperties();
    }

    private PaginationProperties properties(int defaultSize, int maxSize) {
        PaginationProperties properties = new PaginationProperties();
        properties.setDefaultSize(defaultSize);
        properties.setMaxSize(maxSize);
        return properties;
    }

    @Test
    void toPageable_nullPageAndSize_usesFirstPageAndDefaultSize() {
        Pageable pageable = properties().toPageable(null, null, SORT);

        assertThat(pageable.getPageNumber()).isZero();
        assertThat(pageable.getPageSize()).isEqualTo(20);
    }

    @Test
    void toPageable_negativePage_clampsToFirstPage() {
        Pageable pageable = properties().toPageable(-5, null, SORT);

        assertThat(pageable.getPageNumber()).isZero();
    }

    @Test
    void toPageable_positivePage_isPreserved() {
        Pageable pageable = properties().toPageable(3, null, SORT);

        assertThat(pageable.getPageNumber()).isEqualTo(3);
    }

    @Test
    void toPageable_nullSize_usesConfiguredDefaultSize() {
        Pageable pageable = properties(10, 100).toPageable(null, null, SORT);

        assertThat(pageable.getPageSize()).isEqualTo(10);
    }

    @Test
    void toPageable_sizeBelowOne_clampsUpToOne() {
        Pageable pageable = properties().toPageable(null, 0, SORT);

        assertThat(pageable.getPageSize()).isEqualTo(1);
    }

    @Test
    void toPageable_negativeSize_clampsUpToOne() {
        Pageable pageable = properties().toPageable(null, -50, SORT);

        assertThat(pageable.getPageSize()).isEqualTo(1);
    }

    @Test
    void toPageable_sizeAboveMax_clampsDownToConfiguredMax() {
        Pageable pageable = properties(20, 100).toPageable(null, 500, SORT);

        assertThat(pageable.getPageSize()).isEqualTo(100);
    }

    @Test
    void toPageable_sizeExactlyAtMax_isPreserved() {
        Pageable pageable = properties(20, 100).toPageable(null, 100, SORT);

        assertThat(pageable.getPageSize()).isEqualTo(100);
    }

    @Test
    void toPageable_sizeWithinBounds_isPreserved() {
        Pageable pageable = properties().toPageable(null, 42, SORT);

        assertThat(pageable.getPageSize()).isEqualTo(42);
    }

    @Test
    void toPageable_sortIsPassedThrough() {
        Pageable pageable = properties().toPageable(null, null, SORT);

        assertThat(pageable.getSort()).isEqualTo(SORT);
    }
}
