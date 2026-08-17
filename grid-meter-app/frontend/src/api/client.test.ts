import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { apiClient, ApiError } from './client';
import { getToken, setToken } from '../auth/tokenStore';

function jsonResponse(status: number, body: unknown): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(body),
  } as Response;
}

function emptyResponse(status: number): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.reject(new Error('no body')),
  } as Response;
}

describe('apiClient', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    setToken(null);
  });

  it('omits the Authorization header when no token is set', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse(200, {}));

    await apiClient.get('/meters');

    const [, init] = vi.mocked(fetch).mock.calls[0];
    const headers = init?.headers as Headers;
    expect(headers.has('Authorization')).toBe(false);
  });

  it('attaches a Bearer Authorization header when a token is set', async () => {
    setToken('the-token');
    vi.mocked(fetch).mockResolvedValue(jsonResponse(200, {}));

    await apiClient.get('/meters');

    const [, init] = vi.mocked(fetch).mock.calls[0];
    const headers = init?.headers as Headers;
    expect(headers.get('Authorization')).toBe('Bearer the-token');
  });

  it('requests the base-prefixed URL', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse(200, {}));

    await apiClient.get('/meters/abc');

    const [url] = vi.mocked(fetch).mock.calls[0];
    expect(url).toBe('/api/v1/meters/abc');
  });

  it('resolves with the parsed JSON body on success', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse(200, { id: '1' }));

    await expect(apiClient.get('/meters/1')).resolves.toEqual({ id: '1' });
  });

  it('returns undefined for a 204 response without parsing a body', async () => {
    vi.mocked(fetch).mockResolvedValue(emptyResponse(204));

    await expect(apiClient.delete('/meters/1')).resolves.toBeUndefined();
  });

  it('clears the token and throws a 401 ApiError on an unauthorized response', async () => {
    setToken('stale-token');
    vi.mocked(fetch).mockResolvedValue(jsonResponse(401, {}));

    await expect(apiClient.get('/meters')).rejects.toMatchObject({
      status: 401,
      message: 'Session expired — please log in again',
    });
    expect(getToken()).toBeNull();
  });

  it('throws an ApiError using the response body message for other error statuses', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse(404, { message: 'Meter not found' }));

    await expect(apiClient.get('/meters/missing')).rejects.toBeInstanceOf(ApiError);
    await expect(apiClient.get('/meters/missing')).rejects.toMatchObject({
      status: 404,
      message: 'Meter not found',
    });
  });

  it('falls back to a generic message when the error body is not JSON', async () => {
    vi.mocked(fetch).mockResolvedValue(emptyResponse(500));

    await expect(apiClient.get('/meters')).rejects.toMatchObject({
      status: 500,
      message: 'Request failed: 500',
    });
  });

  it('sends a JSON-serialized body and POST method for post()', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse(201, { id: '1' }));

    await apiClient.post('/meters', { serialNumber: 'SN-1' });

    const [, init] = vi.mocked(fetch).mock.calls[0];
    expect(init?.method).toBe('POST');
    expect(init?.body).toBe(JSON.stringify({ serialNumber: 'SN-1' }));
  });

  it('sends a JSON-serialized body and PUT method for put()', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse(200, { id: '1' }));

    await apiClient.put('/meters/1', { serialNumber: 'SN-1' });

    const [, init] = vi.mocked(fetch).mock.calls[0];
    expect(init?.method).toBe('PUT');
    expect(init?.body).toBe(JSON.stringify({ serialNumber: 'SN-1' }));
  });

  it('uses the DELETE method for delete()', async () => {
    vi.mocked(fetch).mockResolvedValue(emptyResponse(204));

    await apiClient.delete('/meters/1');

    const [, init] = vi.mocked(fetch).mock.calls[0];
    expect(init?.method).toBe('DELETE');
  });
});
