import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { metersApi, type MeterRequest, type MeterSearchParams } from '../api/metersApi';

export function useMetersSearch(params: MeterSearchParams) {
  return useQuery({
    queryKey: ['meters', params],
    queryFn: () => metersApi.search(params),
  });
}

export function useMeter(id: string | undefined) {
  return useQuery({
    queryKey: ['meters', id],
    queryFn: () => metersApi.getById(id as string),
    enabled: id !== undefined,
  });
}

export function useCreateMeter() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (request: MeterRequest) => metersApi.create(request),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['meters'] }),
  });
}

export function useUpdateMeter(id: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (request: MeterRequest) => metersApi.update(id, request),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['meters'] }),
  });
}

export function useDeleteMeter() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => metersApi.remove(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['meters'] }),
  });
}
