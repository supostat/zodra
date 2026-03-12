import type { PaymentMethod } from "../../types";

interface PaymentMethodDisplayProps {
  method: PaymentMethod;
}

export function PaymentMethodDisplay({ method }: PaymentMethodDisplayProps) {
  switch (method.type) {
    case "card":
      return (
        <div className="text-sm border rounded p-3">
          <p className="font-medium">Credit Card</p>
          <p>Brand: {method.brand}</p>
          <p>Ending in: {method.lastFour}</p>
          <p>Expires: {method.expiryMonth}/{method.expiryYear}</p>
        </div>
      );
    case "bank_transfer":
      return (
        <div className="text-sm border rounded p-3">
          <p className="font-medium">Bank Transfer</p>
          <p>Bank: {method.bankName}</p>
          <p>Account ending in: {method.accountLastFour}</p>
        </div>
      );
  }
}
