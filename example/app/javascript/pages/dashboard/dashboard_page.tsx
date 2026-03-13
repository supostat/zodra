import { useDashboard } from "../../hooks/use_dashboard";
import { MetricCard } from "../../components/metric_card";
import { formatMoney } from "../../lib/format";
import { ErrorMessage } from "../../components/error_message";
import type { ShowDashboardResponse } from "../../types";

export function DashboardPage() {
  const { data, isLoading, error } = useDashboard();

  if (isLoading) {
    return <p>Loading...</p>;
  }

  if (error) {
    return <ErrorMessage error={error} />;
  }

  const dashboard = data?.data as ShowDashboardResponse | undefined;
  if (!dashboard) return <p>No data</p>;

  const { overview, revenueByStatus, topProducts } = dashboard;

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">Dashboard</h1>

      <div className="mb-8 grid grid-cols-2 gap-4 lg:grid-cols-5">
        <MetricCard label="Total Orders" value={overview.totalOrders} />
        <MetricCard label="Total Revenue" value={formatMoney(overview.totalRevenue)} />
        <MetricCard label="Avg Order Value" value={formatMoney(overview.averageOrderValue)} />
        <MetricCard label="Active Customers" value={overview.activeCustomers} />
        <MetricCard label="Low Stock Products" value={overview.lowStockProducts} />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-lg border bg-white p-4 shadow-sm">
          <h2 className="mb-3 text-lg font-semibold">Revenue by Status</h2>
          {revenueByStatus.length === 0 ? (
            <p className="text-sm text-gray-400">No orders yet</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="py-2">Status</th>
                  <th className="text-right">Orders</th>
                  <th className="text-right">Revenue</th>
                </tr>
              </thead>
              <tbody>
                {revenueByStatus.map((row) => (
                  <tr key={row.status} className="border-b last:border-0">
                    <td className="py-2 capitalize">{row.status}</td>
                    <td className="text-right">{row.count}</td>
                    <td className="text-right">{formatMoney(row.total)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div className="rounded-lg border bg-white p-4 shadow-sm">
          <h2 className="mb-3 text-lg font-semibold">Top Products</h2>
          {topProducts.length === 0 ? (
            <p className="text-sm text-gray-400">No sales yet</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="py-2">Product</th>
                  <th>SKU</th>
                  <th className="text-right">Units</th>
                  <th className="text-right">Revenue</th>
                </tr>
              </thead>
              <tbody>
                {topProducts.map((product) => (
                  <tr key={product.sku} className="border-b last:border-0">
                    <td className="py-2">{product.name}</td>
                    <td className="text-gray-500">{product.sku}</td>
                    <td className="text-right">{product.unitsSold}</td>
                    <td className="text-right">{formatMoney(product.revenue)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
