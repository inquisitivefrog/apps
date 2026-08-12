import { Navigate, Route, Routes } from 'react-router';
import { ProtectedRoute } from './auth/ProtectedRoute';
import { AppLayout } from './components/AppLayout';
import { LoginPage } from './pages/LoginPage';
import { MetersPage } from './pages/MetersPage';
import { MeterDetailPage } from './pages/MeterDetailPage';
import { ReadingsPage } from './pages/ReadingsPage';
import { NotFoundPage } from './pages/NotFoundPage';

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<AppLayout />}>
          <Route path="/" element={<Navigate to="/meters" replace />} />
          <Route path="/meters" element={<MetersPage />} />
          <Route path="/meters/:id" element={<MeterDetailPage />} />
          <Route path="/readings" element={<ReadingsPage />} />
        </Route>
      </Route>
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
