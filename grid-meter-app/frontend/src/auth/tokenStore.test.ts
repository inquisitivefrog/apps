import { describe, expect, it, vi, afterEach } from 'vitest';
import { getToken, setToken, subscribeToken } from './tokenStore';

afterEach(() => {
  setToken(null);
});

describe('tokenStore', () => {
  it('starts with no token', () => {
    expect(getToken()).toBeNull();
  });

  it('returns the value passed to setToken', () => {
    setToken('abc123');
    expect(getToken()).toBe('abc123');
  });

  it('clears the token when set to null', () => {
    setToken('abc123');
    setToken(null);
    expect(getToken()).toBeNull();
  });

  it('notifies subscribers with the new token on change', () => {
    const listener = vi.fn();
    subscribeToken(listener);

    setToken('xyz789');

    expect(listener).toHaveBeenCalledWith('xyz789');
  });

  it('notifies every subscribed listener', () => {
    const first = vi.fn();
    const second = vi.fn();
    subscribeToken(first);
    subscribeToken(second);

    setToken('shared-token');

    expect(first).toHaveBeenCalledWith('shared-token');
    expect(second).toHaveBeenCalledWith('shared-token');
  });

  it('stops notifying a listener after it unsubscribes', () => {
    const listener = vi.fn();
    const unsubscribe = subscribeToken(listener);

    unsubscribe();
    setToken('after-unsubscribe');

    expect(listener).not.toHaveBeenCalled();
  });
});
