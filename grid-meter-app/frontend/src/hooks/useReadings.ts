import { useQuery } from '@tanstack/react-query';
import { readingsApi, type ReadingSearchParams } from '../api/readingsApi';

export function useReadingsSearch(params: ReadingSearchParams) {
  return useQuery({
    queryKey: ['readings', params],
    queryFn: () => readingsApi.search(params),
  });
}

export function useReading(id: string | undefined) {
  return useQuery({
    queryKey: ['readings', id],
    queryFn: () => readingsApi.getById(id as string),
    enabled: id !== undefined,
  });
}
