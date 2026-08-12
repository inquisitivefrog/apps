import { apiClient } from './client';
import type { Page } from './metersApi';

// Read-only, deliberately — readings are immutable events, ingested via POST /readings
// (the endpoint JMeter simulates meter submissions against), never hand-entered through
// the dashboard. No create/update wrapper exists here on purpose.
export interface Reading {
  id: string;
  meterId: string;
  readingTimestamp: string;
  receivedAt: string;
  value: string;
  createdAt: string;
}

export type ReadingSearchParams = {
  meterId?: string;
  from?: string;
  to?: string;
  minValue?: number;
  maxValue?: number;
  page?: number;
  size?: number;
};

function toQueryString(params: Record<string, string | number | undefined>): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== '') {
      search.set(key, String(value));
    }
  }
  const query = search.toString();
  return query ? `?${query}` : '';
}

export const readingsApi = {
  search: (params: ReadingSearchParams) =>
    apiClient.get<Page<Reading>>(`/readings${toQueryString(params)}`),
  getById: (id: string) => apiClient.get<Reading>(`/readings/${id}`),
};
