import type { Order } from "../../types";

const STATUS_COLORS: Record<string, string> = {
  draft: "bg-gray-100 text-gray-700",
  confirmed: "bg-blue-100 text-blue-700",
  shipped: "bg-yellow-100 text-yellow-700",
  delivered: "bg-green-100 text-green-700",
  cancelled: "bg-red-100 text-red-700",
};

interface SsrOrdersListProps {
  orders: Order[];
}

export function SsrOrdersList({ orders }: SsrOrdersListProps) {
  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Orders</h2>

      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2">Number</th>
            <th>Customer</th>
            <th>Status</th>
            <th>Total</th>
            <th>Items</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr key={order.id} className="border-b">
              <td className="py-2 font-mono">{order.number}</td>
              <td>{order.customer.name}</td>
              <td>
                <span className={`px-2 py-0.5 rounded text-xs ${STATUS_COLORS[order.status] ?? ""}`}>
                  {order.status}
                </span>
              </td>
              <td>${order.totalAmount}</td>
              <td>{order.lineItems.length}</td>
              <td>
                <a href={`/ssr/orders/${order.id}`} className="text-blue-600 hover:underline">
                  View
                </a>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
