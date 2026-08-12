// Deliberately bypasses apiClient — login is the one call made with no token yet, and
// apiClient's 401 handler (clear token, throw) doesn't apply to a request that never had one.
const BASE_URL = '/api/v1';

export interface LoginResponse {
  accessToken: string;
  tokenType: string;
  expiresInSeconds: number;
}

export async function login(username: string, password: string): Promise<LoginResponse> {
  const response = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });

  if (!response.ok) {
    throw new Error('Invalid username or password');
  }

  return response.json();
}
