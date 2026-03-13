import type { Product } from "../../types";

interface SsrProductsListProps {
  products: Product[];
}

export function SsrProductsList({ products }: SsrProductsListProps) {
  return (
    <div>
      <h2 className="text-xl font-semibold mb-4">Products</h2>

      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2">Name</th>
            <th>SKU</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Published</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id} className="border-b">
              <td className="py-2">
                <a href={`/ssr/products/${product.id}`} className="text-blue-600 hover:underline">
                  {product.name}
                </a>
              </td>
              <td>{product.sku}</td>
              <td>${product.price}</td>
              <td>{product.stock}</td>
              <td>{product.published ? "Yes" : "No"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
