import { MetricCard } from "../../components/metric_card";
import { formatMoney } from "../../lib/format";

interface Overview {
  total_orders: number;
  total_revenue: string;
  average_order_value: string;
  active_customers: number;
  low_stock_products: number;
}

interface RevenueBreakdown {
  status: string;
  total: number;
  count: number;
}

interface TopProduct {
  name: string;
  sku: string;
  units_sold: number;
  revenue: number;
}

interface DashboardProps {
  overview: Overview;
  revenue_by_status: RevenueBreakdown[];
  top_products: TopProduct[];
}

export function DashboardApp({ overview, revenue_by_status, top_products }: DashboardProps) {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <h1 className="mb-6 text-2xl font-bold">Admin Dashboard</h1>

      <div className="mb-8 grid grid-cols-2 gap-4 lg:grid-cols-5">
        <MetricCard label="Total Orders" value={overview.total_orders} />
        <MetricCard label="Total Revenue" value={formatMoney(overview.total_revenue)} />
        <MetricCard label="Avg Order Value" value={formatMoney(overview.average_order_value)} />
        <MetricCard label="Active Customers" value={overview.active_customers} />
        <MetricCard label="Low Stock Products" value={overview.low_stock_products} />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-lg border bg-white p-4 shadow-sm">
          <h2 className="mb-3 text-lg font-semibold">Revenue by Status</h2>
          {revenue_by_status.length === 0 ? (
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
                {revenue_by_status.map((row) => (
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
          {top_products.length === 0 ? (
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
                {top_products.map((product) => (
                  <tr key={product.sku} className="border-b last:border-0">
                    <td className="py-2">{product.name}</td>
                    <td className="text-gray-500">{product.sku}</td>
                    <td className="text-right">{product.units_sold}</td>
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
