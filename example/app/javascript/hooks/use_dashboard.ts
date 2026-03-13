import { useQuery } from "@tanstack/react-query";
import { api } from "../api";

const DASHBOARD_KEY = ["dashboard"] as const;

export function useDashboard() {
  return useQuery({
    queryKey: DASHBOARD_KEY,
    queryFn: () => api.dashboard.show({}),
  });
}
