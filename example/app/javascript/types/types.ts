export interface Product {
  id: string;
  name: string;
  sku: string;
  price: number;
  stock: number;
  published: boolean;
}

export interface IndexProductsParams {

}

export interface ShowProductsParams {
  id: string;
}

export interface CreateProductsParams {
  name: string;
  sku: string;
  price: number;
  stock: number;
  published: boolean;
}

export interface UpdateProductsParams {
  id: string;
  name?: string;
  sku?: string;
  price?: number;
  stock?: number;
  published?: boolean;
}

export interface DestroyProductsParams {
  id: string;
}

export interface ProductsContract {
  index: { method: 'GET'; path: '/api/v1/products'; params: IndexProductsParams; response: Product };
  show: { method: 'GET'; path: '/api/v1/products/:id'; params: ShowProductsParams; response: Product };
  create: { method: 'POST'; path: '/api/v1/products'; params: CreateProductsParams; response: Product };
  update: { method: 'PATCH'; path: '/api/v1/products/:id'; params: UpdateProductsParams; response: Product };
  destroy: { method: 'DELETE'; path: '/api/v1/products/:id'; params: DestroyProductsParams };
}
