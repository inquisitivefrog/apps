import { apiClient } from './client';

export type MeterStatus = 'ACTIVE' | 'INACTIVE' | 'MAINTENANCE';

export interface Meter {
  id: string;
  serialNumber: string;
  location: string;
  status: MeterStatus;
  installedAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface MeterRequest {
  serialNumber: string;
  location: string;
  status: MeterStatus;
  installedAt: string;
}

export interface Page<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export type MeterSearchParams = {
  location?: string;
  status?: MeterStatus;
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

export const metersApi = {
  search: (params: MeterSearchParams) =>
    apiClient.get<Page<Meter>>(`/meters${toQueryString(params)}`),
  getById: (id: string) => apiClient.get<Meter>(`/meters/${id}`),
  create: (request: MeterRequest) => apiClient.post<Meter>('/meters', request),
  update: (id: string, request: MeterRequest) => apiClient.put<Meter>(`/meters/${id}`, request),
  remove: (id: string) => apiClient.delete(`/meters/${id}`),
};
