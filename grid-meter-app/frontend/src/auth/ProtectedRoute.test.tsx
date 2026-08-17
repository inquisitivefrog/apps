import { render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router';
import { ProtectedRoute } from './ProtectedRoute';
import { AuthProvider } from './AuthContext';
import { setToken } from './tokenStore';

function renderProtectedRoute() {
  return render(
    <MemoryRouter initialEntries={['/meters']}>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<div>Login Page</div>} />
          <Route element={<ProtectedRoute />}>
            <Route path="/meters" element={<div>Secret Meters Content</div>} />
          </Route>
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}

afterEach(() => {
  setToken(null);
});

describe('ProtectedRoute', () => {
  it('redirects to /login when there is no token', () => {
    renderProtectedRoute();

    expect(screen.getByText('Login Page')).toBeInTheDocument();
    expect(screen.queryByText('Secret Meters Content')).not.toBeInTheDocument();
  });

  it('renders the nested route when a token is set', () => {
    setToken('valid-token');

    renderProtectedRoute();

    expect(screen.getByText('Secret Meters Content')).toBeInTheDocument();
    expect(screen.queryByText('Login Page')).not.toBeInTheDocument();
  });
});
