package com.gridmeter.api.common;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "grid-meter.pagination")
public class PaginationProperties {

    private int defaultSize = 20;
    private int maxSize = 100;

    public int getDefaultSize() {
        return defaultSize;
    }

    public void setDefaultSize(int defaultSize) {
        this.defaultSize = defaultSize;
    }

    public int getMaxSize() {
        return maxSize;
    }

    public void setMaxSize(int maxSize) {
        this.maxSize = maxSize;
    }

    /** Clamps requested page/size to server-enforced bounds — never trust a client-supplied size. */
    public Pageable toPageable(Integer page, Integer size, Sort sort) {
        int safePage = page == null || page < 0 ? 0 : page;
        int safeSize = size == null ? defaultSize : Math.min(Math.max(size, 1), maxSize);
        return PageRequest.of(safePage, safeSize, sort);
    }
}
