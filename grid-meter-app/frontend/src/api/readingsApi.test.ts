import { afterEach, describe, expect, it, vi } from 'vitest';
import { readingsApi } from './readingsApi';
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
});

describe('readingsApi.search', () => {
  it('requests /readings with no query string when no params are given', () => {
    readingsApi.search({});

    expect(apiClient.get).toHaveBeenCalledWith('/readings');
  });

  it('includes only the params that are set', () => {
    readingsApi.search({ meterId: 'meter-a', minValue: 10, maxValue: 100, page: 1 });

    expect(apiClient.get).toHaveBeenCalledWith(
      '/readings?meterId=meter-a&minValue=10&maxValue=100&page=1',
    );
  });

  it('omits params that are undefined or an empty string', () => {
    readingsApi.search({ meterId: '', from: undefined, page: 0 });

    expect(apiClient.get).toHaveBeenCalledWith('/readings?page=0');
  });
});

describe('readingsApi.getById', () => {
  it('requests /readings/{id}', () => {
    readingsApi.getById('reading-a');

    expect(apiClient.get).toHaveBeenCalledWith('/readings/reading-a');
  });
});
