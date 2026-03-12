import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import type { z } from "zod";
import { CreateProductsParamsSchema } from "../../types/schemas";
import { useCreateProduct, useUpdateProduct, useProduct } from "../../hooks/use_products";
import { FieldError } from "../../components/field_error";
import { ErrorMessage } from "../../components/error_message";

type ProductFormValues = z.input<typeof CreateProductsParamsSchema>;

interface ProductFormProps {
  productId: string | null;
  onClose: () => void;
}

export function ProductForm({ productId, onClose }: ProductFormProps) {
  const isEditing = productId !== null;
  const { data: existing } = useProduct(productId ?? "", { enabled: isEditing });
  const createProduct = useCreateProduct();
  const updateProduct = useUpdateProduct();
  const mutation = isEditing ? updateProduct : createProduct;

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ProductFormValues>({
    resolver: zodResolver(CreateProductsParamsSchema),
    values: isEditing && existing?.data ? {
      name: existing.data.name,
      sku: existing.data.sku,
      price: existing.data.price,
      stock: existing.data.stock,
      published: existing.data.published,
    } : undefined,
  });

  function onSubmit(data: ProductFormValues) {
    if (isEditing) {
      updateProduct.mutate({ id: productId!, ...data }, { onSuccess: onClose });
    } else {
      createProduct.mutate(data as z.output<typeof CreateProductsParamsSchema>, { onSuccess: onClose });
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="border rounded p-4 mb-4 space-y-3">
      <h3 className="font-semibold">{isEditing ? "Edit" : "New"} Product</h3>

      <ErrorMessage error={mutation.error} />

      <div>
        <label className="block text-sm font-medium">Name</label>
        <input {...register("name")} className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.name?.message} />
      </div>

      <div>
        <label className="block text-sm font-medium">SKU</label>
        <input {...register("sku")} className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.sku?.message} />
      </div>

      <div>
        <label className="block text-sm font-medium">Price</label>
        <input {...register("price", { valueAsNumber: true })} type="number" step="0.01"
               className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.price?.message} />
      </div>

      <div>
        <label className="block text-sm font-medium">Stock</label>
        <input {...register("stock", { valueAsNumber: true })} type="number"
               className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.stock?.message} />
      </div>

      <div className="flex items-center gap-2">
        <input {...register("published")} type="checkbox" />
        <label className="text-sm">Published</label>
      </div>

      <div className="flex gap-2">
        <button type="submit" disabled={mutation.isPending}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50">
          {mutation.isPending ? "Saving..." : "Save"}
        </button>
        <button type="button" onClick={onClose}
                className="px-4 py-2 border rounded hover:bg-gray-50">
          Cancel
        </button>
      </div>
    </form>
  );
}
