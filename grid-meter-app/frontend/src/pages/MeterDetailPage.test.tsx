import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router';
import { MeterDetailPage } from './MeterDetailPage';
import { createTestQueryClient } from '../testUtils';
import { metersApi, type Meter } from '../api/metersApi';

vi.mock('../api/metersApi', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../api/metersApi')>();
  return {
    ...actual,
    metersApi: {
      search: vi.fn(),
      getById: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      remove: vi.fn(),
    },
  };
});

const METER: Meter = {
  id: 'meter-a',
  serialNumber: 'SN-A',
  location: 'Main St',
  status: 'ACTIVE',
  installedAt: '2026-01-15T00:00:00Z',
  createdAt: '2026-01-15T00:00:00Z',
  updatedAt: '2026-01-15T00:00:00Z',
};

function renderMeterDetailPage() {
  const queryClient = createTestQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/meters/meter-a']}>
        <Routes>
          <Route path="/meters/:id" element={<MeterDetailPage />} />
          <Route path="/meters" element={<div>Meters List Page</div>} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

afterEach(() => {
  vi.mocked(metersApi.getById).mockReset();
  vi.mocked(metersApi.update).mockReset();
});

describe('MeterDetailPage', () => {
  it('shows a loading state before the meter loads', () => {
    vi.mocked(metersApi.getById).mockReturnValue(new Promise(() => {}));

    renderMeterDetailPage();

    expect(screen.getByText('Loading…')).toBeInTheDocument();
  });

  it('populates the form once the meter loads', async () => {
    vi.mocked(metersApi.getById).mockResolvedValue(METER);

    renderMeterDetailPage();

    expect(await screen.findByDisplayValue('SN-A')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Main St')).toBeInTheDocument();
    expect(screen.getByDisplayValue('2026-01-15')).toBeInTheDocument();
    expect(metersApi.getById).toHaveBeenCalledWith('meter-a');
  });

  it('saves the edited fields and navigates back to /meters', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.getById).mockResolvedValue(METER);
    vi.mocked(metersApi.update).mockResolvedValue({ ...METER, location: 'Elm St' });
    renderMeterDetailPage();
    await screen.findByDisplayValue('SN-A');

    const locationField = screen.getByLabelText('Location');
    await user.clear(locationField);
    await user.type(locationField, 'Elm St');
    await user.click(screen.getByRole('button', { name: 'Save' }));

    await waitFor(() =>
      expect(metersApi.update).toHaveBeenCalledWith('meter-a', {
        serialNumber: 'SN-A',
        location: 'Elm St',
        status: 'ACTIVE',
        installedAt: new Date('2026-01-15').toISOString(),
      }),
    );
    expect(await screen.findByText('Meters List Page')).toBeInTheDocument();
  });

  it('navigates back to /meters on Cancel without saving', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.getById).mockResolvedValue(METER);
    renderMeterDetailPage();
    await screen.findByDisplayValue('SN-A');

    await user.click(screen.getByRole('button', { name: 'Cancel' }));

    expect(await screen.findByText('Meters List Page')).toBeInTheDocument();
    expect(metersApi.update).not.toHaveBeenCalled();
  });
});
