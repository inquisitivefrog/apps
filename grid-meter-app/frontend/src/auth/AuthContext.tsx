import { createContext, useContext, useSyncExternalStore, type ReactNode } from 'react';
import { getToken, setToken, subscribeToken } from './tokenStore';
import { login as loginRequest } from '../api/authApi';

interface AuthContextValue {
  isAuthenticated: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const token = useSyncExternalStore(subscribeToken, getToken);

  const value: AuthContextValue = {
    isAuthenticated: token !== null,
    login: async (username, password) => {
      const response = await loginRequest(username, password);
      setToken(response.accessToken);
    },
    logout: () => setToken(null),
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
