import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router';
import { MetersPage } from './MetersPage';
import { createTestQueryClient } from '../testUtils';
import { metersApi, type Meter, type Page } from '../api/metersApi';

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

const METER_A: Meter = {
  id: 'meter-a',
  serialNumber: 'SN-A',
  location: 'Main St',
  status: 'ACTIVE',
  installedAt: '2026-01-15T00:00:00Z',
  createdAt: '2026-01-15T00:00:00Z',
  updatedAt: '2026-01-15T00:00:00Z',
};

const METER_B: Meter = {
  id: 'meter-b',
  serialNumber: 'SN-B',
  location: 'Oak Ave',
  status: 'INACTIVE',
  installedAt: '2026-02-01T00:00:00Z',
  createdAt: '2026-02-01T00:00:00Z',
  updatedAt: '2026-02-01T00:00:00Z',
};

function page(content: Meter[], overrides: Partial<Page<Meter>> = {}): Page<Meter> {
  return { content, page: 0, size: 20, totalElements: content.length, totalPages: 1, ...overrides };
}

function renderMetersPage() {
  const queryClient = createTestQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/meters']}>
        <Routes>
          <Route path="/meters" element={<MetersPage />} />
          <Route path="/meters/:id" element={<div>Meter Detail Page</div>} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

afterEach(() => {
  vi.mocked(metersApi.search).mockReset();
  vi.mocked(metersApi.create).mockReset();
});

describe('MetersPage', () => {
  it('renders meters returned by the search', async () => {
    vi.mocked(metersApi.search).mockResolvedValue(page([METER_A, METER_B]));

    renderMetersPage();

    expect(await screen.findByText('SN-A')).toBeInTheDocument();
    expect(screen.getByText('SN-B')).toBeInTheDocument();
    expect(screen.getByText('Main St')).toBeInTheDocument();
  });

  it('renders the Installed date as the calendar date entered, not shifted by local timezone', async () => {
    // installedAt is a date-only value stored as UTC midnight (see the "date" input in
    // CreateMeterDialog below). Pinning TZ to a zone west of UTC reproduces the regression this
    // guards against: naively parsing "2026-01-15T00:00:00Z" and rendering with the JS engine's
    // local timezone rolls the displayed date back to 1/14/2026 — see GitHub issue #2.
    vi.stubEnv('TZ', 'America/Los_Angeles');
    try {
      vi.mocked(metersApi.search).mockResolvedValue(page([METER_A]));

      renderMetersPage();

      await screen.findByText('SN-A');
      expect(screen.getByText('1/15/2026')).toBeInTheDocument();
    } finally {
      vi.unstubAllEnvs();
    }
  });

  it('re-searches with the location filter and resets to page 0', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([METER_A]));
    renderMetersPage();
    await screen.findByText('SN-A');

    await user.type(screen.getByLabelText('Location'), 'Main');

    await waitFor(() =>
      expect(metersApi.search).toHaveBeenLastCalledWith({
        location: 'Main',
        status: undefined,
        page: 0,
        size: 20,
      }),
    );
  });

  it('re-searches with the selected status filter', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([METER_A]));
    renderMetersPage();
    await screen.findByText('SN-A');

    await user.click(screen.getByRole('combobox', { name: 'Status' }));
    await user.click(await screen.findByRole('option', { name: 'ACTIVE' }));

    await waitFor(() =>
      expect(metersApi.search).toHaveBeenLastCalledWith({
        location: undefined,
        status: 'ACTIVE',
        page: 0,
        size: 20,
      }),
    );
  });

  it('navigates to the meter detail page when a row is clicked', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([METER_A]));
    renderMetersPage();

    await user.click(await screen.findByText('SN-A'));

    expect(await screen.findByText('Meter Detail Page')).toBeInTheDocument();
  });

  it('requests the next page when pagination advances', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([METER_A], { totalElements: 50 }));
    renderMetersPage();
    await screen.findByText('SN-A');

    await user.click(screen.getByRole('button', { name: 'Go to next page' }));

    await waitFor(() =>
      expect(metersApi.search).toHaveBeenLastCalledWith({
        location: undefined,
        status: undefined,
        page: 1,
        size: 20,
      }),
    );
  });

  it('disables Create until the required fields are filled in', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([]));
    renderMetersPage();

    await user.click(screen.getByRole('button', { name: 'New Meter' }));
    const dialog = screen.getByRole('dialog');

    expect(within(dialog).getByRole('button', { name: 'Create' })).toBeDisabled();

    await user.type(within(dialog).getByLabelText('Serial Number'), 'SN-NEW');
    await user.type(within(dialog).getByLabelText('Location'), 'Elm St');
    const dateInput = within(dialog).getByLabelText('Installed At');
    await user.type(dateInput, '2026-03-01');

    expect(within(dialog).getByRole('button', { name: 'Create' })).toBeEnabled();
  });

  it('creates a meter and closes the dialog on submit', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([]));
    vi.mocked(metersApi.create).mockResolvedValue(METER_A);
    renderMetersPage();

    await user.click(screen.getByRole('button', { name: 'New Meter' }));
    const dialog = screen.getByRole('dialog');
    await user.type(within(dialog).getByLabelText('Serial Number'), 'SN-NEW');
    await user.type(within(dialog).getByLabelText('Location'), 'Elm St');
    await user.type(within(dialog).getByLabelText('Installed At'), '2026-03-01');

    await user.click(within(dialog).getByRole('button', { name: 'Create' }));

    await waitFor(() =>
      expect(metersApi.create).toHaveBeenCalledWith({
        serialNumber: 'SN-NEW',
        location: 'Elm St',
        status: 'ACTIVE',
        installedAt: new Date('2026-03-01').toISOString(),
      }),
    );
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  });

  it('closes the dialog without creating when Cancel is clicked', async () => {
    const user = userEvent.setup();
    vi.mocked(metersApi.search).mockResolvedValue(page([]));
    renderMetersPage();

    await user.click(screen.getByRole('button', { name: 'New Meter' }));
    await user.click(screen.getByRole('button', { name: 'Cancel' }));

    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
    expect(metersApi.create).not.toHaveBeenCalled();
  });
});
