import { useState } from "react";
import { useProducts, useDeleteProduct } from "../../hooks/use_products";
import { ErrorMessage } from "../../components/error_message";
import { ProductForm } from "./product_form";
import type { Product } from "../../types/types";

export function ProductsPage() {
  const { data, isLoading, error } = useProducts();
  const deleteProduct = useDeleteProduct();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  if (isLoading) return <p>Loading...</p>;
  if (error) return <ErrorMessage error={error} />;

  const products = (data?.data ?? []) as Product[];

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold">Products</h2>
        <button
          onClick={() => { setShowForm(true); setEditingId(null); }}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          New Product
        </button>
      </div>

      {showForm && (
        <ProductForm
          productId={editingId}
          onClose={() => { setShowForm(false); setEditingId(null); }}
        />
      )}

      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2">Name</th>
            <th>SKU</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Published</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id} className="border-b">
              <td className="py-2">{product.name}</td>
              <td>{product.sku}</td>
              <td>${product.price}</td>
              <td>{product.stock}</td>
              <td>{product.published ? "Yes" : "No"}</td>
              <td className="space-x-2">
                <button
                  onClick={() => { setEditingId(product.id); setShowForm(true); }}
                  className="text-blue-600 hover:underline"
                >
                  Edit
                </button>
                <button
                  onClick={() => {
                    if (confirm("Delete this product?")) {
                      deleteProduct.mutate(product.id);
                    }
                  }}
                  className="text-red-600 hover:underline"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
