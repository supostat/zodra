import { useParams, Link } from "react-router";
import { useOrder, useConfirmOrder, useCancelOrder } from "../../hooks/use_orders";
import { ErrorMessage } from "../../components/error_message";
import { PaymentMethodDisplay } from "./payment_method_display";

export function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data, isLoading, error } = useOrder(id!);
  const confirmOrder = useConfirmOrder();
  const cancelOrder = useCancelOrder();

  if (isLoading) return <p>Loading...</p>;
  if (error) return <ErrorMessage error={error} />;

  const order = data?.data;
  if (!order) return <p>Order not found</p>;

  const canConfirm = order.status === "draft";
  const canCancel = order.status !== "delivered" && order.status !== "cancelled";

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link to="/orders" className="text-blue-600 hover:underline text-sm">&larr; Orders</Link>
        <h2 className="text-xl font-semibold">Order {order.number}</h2>
      </div>

      <ErrorMessage error={confirmOrder.error} />
      <ErrorMessage error={cancelOrder.error} />

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

      <div className="flex gap-2">
        {canConfirm && (
          <button
            onClick={() => confirmOrder.mutate(id!)}
            disabled={confirmOrder.isPending}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
          >
            {confirmOrder.isPending ? "Confirming..." : "Confirm Order"}
          </button>
        )}
        {canCancel && (
          <button
            onClick={() => cancelOrder.mutate(id!)}
            disabled={cancelOrder.isPending}
            className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
          >
            {cancelOrder.isPending ? "Cancelling..." : "Cancel Order"}
          </button>
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

      <div>
        <h3 className="font-semibold mb-2">Payment Method</h3>
        <PaymentMethodDisplay method={order.paymentMethod} />
      </div>
    </div>
  );
}
