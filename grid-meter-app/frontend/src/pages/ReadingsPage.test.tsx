import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { QueryClientProvider } from '@tanstack/react-query';
import { ReadingsPage } from './ReadingsPage';
import { createTestQueryClient } from '../testUtils';
import { readingsApi, type Reading } from '../api/readingsApi';
import type { Page } from '../api/metersApi';

vi.mock('../api/readingsApi', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../api/readingsApi')>();
  return {
    ...actual,
    readingsApi: {
      search: vi.fn(),
      getById: vi.fn(),
    },
  };
});

const READING: Reading = {
  id: 'reading-a',
  meterId: 'meter-a',
  readingTimestamp: '2026-01-15T10:00:00Z',
  receivedAt: '2026-01-15T10:00:05Z',
  value: '42.5',
  createdAt: '2026-01-15T10:00:05Z',
};

function page(content: Reading[], overrides: Partial<Page<Reading>> = {}): Page<Reading> {
  return { content, page: 0, size: 20, totalElements: content.length, totalPages: 1, ...overrides };
}

function renderReadingsPage() {
  const queryClient = createTestQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      <ReadingsPage />
    </QueryClientProvider>,
  );
}

afterEach(() => {
  vi.mocked(readingsApi.search).mockReset();
});

describe('ReadingsPage', () => {
  it('renders readings returned by the search', async () => {
    vi.mocked(readingsApi.search).mockResolvedValue(page([READING]));

    renderReadingsPage();

    expect(await screen.findByText('meter-a')).toBeInTheDocument();
    expect(screen.getByText('42.5')).toBeInTheDocument();
  });

  it('re-searches with the meter ID filter and resets to page 0', async () => {
    const user = userEvent.setup();
    vi.mocked(readingsApi.search).mockResolvedValue(page([READING]));
    renderReadingsPage();
    await screen.findByText('meter-a');

    await user.type(screen.getByLabelText('Meter ID'), 'meter-a');

    await waitFor(() =>
      expect(readingsApi.search).toHaveBeenLastCalledWith({
        meterId: 'meter-a',
        page: 0,
        size: 20,
      }),
    );
  });

  it('requests the next page when pagination advances', async () => {
    const user = userEvent.setup();
    vi.mocked(readingsApi.search).mockResolvedValue(page([READING], { totalElements: 50 }));
    renderReadingsPage();
    await screen.findByText('meter-a');

    await user.click(screen.getByRole('button', { name: 'Go to next page' }));

    await waitFor(() =>
      expect(readingsApi.search).toHaveBeenLastCalledWith({
        meterId: undefined,
        page: 1,
        size: 20,
      }),
    );
  });

  it('renders no create or edit affordances — readings are immutable', async () => {
    vi.mocked(readingsApi.search).mockResolvedValue(page([READING]));

    renderReadingsPage();
    await screen.findByText('meter-a');

    expect(screen.queryByRole('button', { name: /new reading/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /edit/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /save/i })).not.toBeInTheDocument();
  });
});
