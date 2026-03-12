import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "../api";
import type { CreateOrdersParams, SearchOrdersParams } from "../types/types";

const ORDERS_KEY = ["orders"] as const;

export function useOrders() {
  return useQuery({
    queryKey: ORDERS_KEY,
    queryFn: () => api.orders.index({}),
  });
}

export function useOrder(id: string) {
  return useQuery({
    queryKey: [...ORDERS_KEY, id],
    queryFn: () => api.orders.show({ id }),
  });
}

export function useCreateOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (params: CreateOrdersParams) => api.orders.create(params),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ORDERS_KEY }),
  });
}

export function useConfirmOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.orders.confirm({ id }),
    onSuccess: (_data, id) => {
      queryClient.invalidateQueries({ queryKey: ORDERS_KEY });
      queryClient.invalidateQueries({ queryKey: [...ORDERS_KEY, id] });
    },
  });
}

export function useCancelOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.orders.cancel({ id }),
    onSuccess: (_data, id) => {
      queryClient.invalidateQueries({ queryKey: ORDERS_KEY });
      queryClient.invalidateQueries({ queryKey: [...ORDERS_KEY, id] });
    },
  });
}

export function useSearchOrders(params: SearchOrdersParams) {
  return useQuery({
    queryKey: [...ORDERS_KEY, "search", params],
    queryFn: () => api.orders.search(params),
  });
}
