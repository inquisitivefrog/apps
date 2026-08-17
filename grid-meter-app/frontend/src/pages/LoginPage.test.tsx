import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router';
import { LoginPage } from './LoginPage';
import { AuthProvider } from '../auth/AuthContext';
import { setToken } from '../auth/tokenStore';
import { login } from '../api/authApi';

vi.mock('../api/authApi', () => ({
  login: vi.fn(),
}));

function renderLoginPage() {
  return render(
    <MemoryRouter initialEntries={['/login']}>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/meters" element={<div>Meters Page</div>} />
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}

afterEach(() => {
  setToken(null);
  vi.mocked(login).mockReset();
});

describe('LoginPage', () => {
  it('renders the login form', () => {
    renderLoginPage();

    expect(screen.getByLabelText('Username')).toBeInTheDocument();
    expect(screen.getByLabelText('Password')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Log in' })).toBeInTheDocument();
  });

  it('navigates to /meters after a successful login', async () => {
    const user = userEvent.setup();
    vi.mocked(login).mockResolvedValue({
      accessToken: 'new-token',
      tokenType: 'Bearer',
      expiresInSeconds: 3600,
    });
    renderLoginPage();

    await user.type(screen.getByLabelText('Username'), 'demo');
    await user.type(screen.getByLabelText('Password'), 'GridMeter!Demo2026');
    await user.click(screen.getByRole('button', { name: 'Log in' }));

    expect(login).toHaveBeenCalledWith('demo', 'GridMeter!Demo2026');
    await waitFor(() => expect(screen.getByText('Meters Page')).toBeInTheDocument());
  });

  it('shows an error and stays on the login page when login fails', async () => {
    const user = userEvent.setup();
    vi.mocked(login).mockRejectedValue(new Error('Invalid username or password'));
    renderLoginPage();

    await user.type(screen.getByLabelText('Username'), 'demo');
    await user.type(screen.getByLabelText('Password'), 'wrong-password');
    await user.click(screen.getByRole('button', { name: 'Log in' }));

    expect(await screen.findByText('Invalid username or password')).toBeInTheDocument();
    expect(screen.queryByText('Meters Page')).not.toBeInTheDocument();
  });

  it('redirects straight to /meters if already authenticated', () => {
    setToken('already-logged-in');

    renderLoginPage();

    expect(screen.getByText('Meters Page')).toBeInTheDocument();
    expect(screen.queryByLabelText('Username')).not.toBeInTheDocument();
  });
});
