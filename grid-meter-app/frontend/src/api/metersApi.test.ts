import { afterEach, describe, expect, it, vi } from 'vitest';
import { metersApi, type MeterRequest } from './metersApi';
import { apiClient } from './client';

vi.mock('./client', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}));

afterEach(() => {
  vi.mocked(apiClient.get).mockReset();
  vi.mocked(apiClient.post).mockReset();
  vi.mocked(apiClient.put).mockReset();
  vi.mocked(apiClient.delete).mockReset();
});

describe('metersApi.search', () => {
  it('requests /meters with no query string when no params are given', () => {
    metersApi.search({});

    expect(apiClient.get).toHaveBeenCalledWith('/meters');
  });

  it('includes only the params that are set', () => {
    metersApi.search({ location: 'Main St', page: 2 });

    expect(apiClient.get).toHaveBeenCalledWith('/meters?location=Main+St&page=2');
  });

  it('omits params that are undefined or an empty string', () => {
    metersApi.search({ location: '', status: undefined, page: 0 });

    expect(apiClient.get).toHaveBeenCalledWith('/meters?page=0');
  });

  it('includes a status filter', () => {
    metersApi.search({ status: 'ACTIVE' });

    expect(apiClient.get).toHaveBeenCalledWith('/meters?status=ACTIVE');
  });
});

describe('metersApi other operations', () => {
  it('getById requests /meters/{id}', () => {
    metersApi.getById('abc-123');

    expect(apiClient.get).toHaveBeenCalledWith('/meters/abc-123');
  });

  it('create posts to /meters with the request body', () => {
    const request: MeterRequest = {
      serialNumber: 'SN-1',
      location: 'Main St',
      status: 'ACTIVE',
      installedAt: '2026-01-01T00:00:00Z',
    };

    metersApi.create(request);

    expect(apiClient.post).toHaveBeenCalledWith('/meters', request);
  });

  it('update puts to /meters/{id} with the request body', () => {
    const request: MeterRequest = {
      serialNumber: 'SN-1',
      location: 'Main St',
      status: 'MAINTENANCE',
      installedAt: '2026-01-01T00:00:00Z',
    };

    metersApi.update('abc-123', request);

    expect(apiClient.put).toHaveBeenCalledWith('/meters/abc-123', request);
  });

  it('remove deletes /meters/{id}', () => {
    metersApi.remove('abc-123');

    expect(apiClient.delete).toHaveBeenCalledWith('/meters/abc-123');
  });
});
