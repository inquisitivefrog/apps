import { act, renderHook, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import type { ReactNode } from 'react';
import { AuthProvider, useAuth } from './AuthContext';
import { setToken, getToken } from './tokenStore';
import { login } from '../api/authApi';

vi.mock('../api/authApi', () => ({
  login: vi.fn(),
}));

const wrapper = ({ children }: { children: ReactNode }) => <AuthProvider>{children}</AuthProvider>;

afterEach(() => {
  setToken(null);
  vi.mocked(login).mockReset();
});

describe('AuthContext', () => {
  it('starts unauthenticated when no token is set', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.isAuthenticated).toBe(false);
  });

  it('becomes authenticated and stores the token after a successful login', async () => {
    vi.mocked(login).mockResolvedValue({
      accessToken: 'new-token',
      tokenType: 'Bearer',
      expiresInSeconds: 3600,
    });
    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      await result.current.login('demo', 'GridMeter!Demo2026');
    });

    expect(login).toHaveBeenCalledWith('demo', 'GridMeter!Demo2026');
    await waitFor(() => expect(result.current.isAuthenticated).toBe(true));
    expect(getToken()).toBe('new-token');
  });

  it('propagates the error and stays unauthenticated when login fails', async () => {
    vi.mocked(login).mockRejectedValue(new Error('Invalid username or password'));
    const { result } = renderHook(() => useAuth(), { wrapper });

    await expect(
      act(async () => {
        await result.current.login('demo', 'wrong-password');
      }),
    ).rejects.toThrow('Invalid username or password');

    expect(result.current.isAuthenticated).toBe(false);
    expect(getToken()).toBeNull();
  });

  it('clears the token and becomes unauthenticated on logout', async () => {
    vi.mocked(login).mockResolvedValue({
      accessToken: 'new-token',
      tokenType: 'Bearer',
      expiresInSeconds: 3600,
    });
    const { result } = renderHook(() => useAuth(), { wrapper });
    await act(async () => {
      await result.current.login('demo', 'GridMeter!Demo2026');
    });
    await waitFor(() => expect(result.current.isAuthenticated).toBe(true));

    act(() => {
      result.current.logout();
    });

    expect(result.current.isAuthenticated).toBe(false);
    expect(getToken()).toBeNull();
  });
});
