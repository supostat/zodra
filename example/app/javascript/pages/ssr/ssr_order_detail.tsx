import type { Order } from "../../types";
import { PaymentMethodDisplay } from "../orders/payment_method_display";

interface SsrOrderDetailProps {
  order: Order;
}

export function SsrOrderDetail({ order }: SsrOrderDetailProps) {
  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <a href="/ssr/orders" className="text-blue-600 hover:underline text-sm">&larr; Orders</a>
        <h2 className="text-xl font-semibold">Order {order.number}</h2>
      </div>

      <div className="grid grid-cols-2 gap-4 text-sm">
        <div>
          <span className="text-gray-500">Status:</span> {order.status}
        </div>
        <div>
          <span className="text-gray-500">Customer:</span> {order.customer.name} ({order.customer.email})
        </div>
        <div>
          <span className="text-gray-500">Total:</span> ${order.totalAmount}
        </div>
        {order.shippingAddress && (
          <div>
            <span className="text-gray-500">Shipping:</span> {order.shippingAddress}
          </div>
        )}
        {order.estimatedDelivery && (
          <div>
            <span className="text-gray-500">Est. delivery:</span> {order.estimatedDelivery}
          </div>
        )}
      </div>

      <div>
        <h3 className="font-semibold mb-2">Line Items</h3>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b text-left">
              <th className="py-2">Product</th>
              <th>Qty</th>
              <th>Unit Price</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {order.lineItems.map((item) => (
              <tr key={item.id} className="border-b">
                <td className="py-2">{item.product.name}</td>
                <td>{item.quantity}</td>
                <td>${item.unitPrice}</td>
                <td>${item.totalPrice}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {order.paymentMethod && (
        <div>
          <h3 className="font-semibold mb-2">Payment Method</h3>
          <PaymentMethodDisplay method={order.paymentMethod} />
        </div>
      )}
    </div>
  );
}
