import type { Product } from "../../types";

interface SsrProductDetailProps {
  product: Product;
}

export function SsrProductDetail({ product }: SsrProductDetailProps) {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <a href="/ssr/products" className="text-blue-600 hover:underline text-sm">&larr; Products</a>
        <h2 className="text-xl font-semibold">{product.name}</h2>
      </div>

      <dl className="grid grid-cols-2 gap-2 text-sm">
        <dt className="text-gray-500">SKU</dt>
        <dd>{product.sku}</dd>
        <dt className="text-gray-500">Price</dt>
        <dd>${product.price}</dd>
        <dt className="text-gray-500">Stock</dt>
        <dd>{product.stock}</dd>
        <dt className="text-gray-500">Published</dt>
        <dd>{product.published ? "Yes" : "No"}</dd>
      </dl>
    </div>
  );
}
