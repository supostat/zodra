import { NavLink, Outlet, useLocation } from "react-router";

const NAV_ITEMS = [
  { to: "/dashboard", label: "Dashboard" },
  { to: "/products", label: "Products" },
  { to: "/orders", label: "Orders" },
  { to: "/settings", label: "Settings" },
];

const SPA_TO_SSR: Record<string, string> = {
  "/dashboard": "/ssr/dashboard",
  "/products": "/ssr/products",
  "/orders": "/ssr/orders",
  "/settings": "/ssr/settings",
};

function ssrPathFor(spaPath: string): string {
  for (const [prefix, ssrPrefix] of Object.entries(SPA_TO_SSR)) {
    if (spaPath.startsWith(prefix)) {
      return spaPath.replace(prefix, ssrPrefix);
    }
  }
  return "/ssr/dashboard";
}

export function Layout() {
  const location = useLocation();

  return (
    <div className="flex min-h-screen">
      <nav className="w-56 border-r bg-gray-50 p-4">
        <h1 className="text-lg font-bold mb-6">Zodra</h1>
        <ul className="space-y-1">
          {NAV_ITEMS.map(({ to, label }) => (
            <li key={to}>
              <NavLink
                to={to}
                className={({ isActive }) =>
                  `block px-3 py-2 rounded ${isActive ? "bg-blue-100 text-blue-700 font-medium" : "text-gray-700 hover:bg-gray-100"}`
                }
              >
                {label}
              </NavLink>
            </li>
          ))}
        </ul>
        <div className="mt-6 border-t pt-4">
          <div className="flex rounded-md overflow-hidden border text-xs font-medium">
            <span className="flex-1 text-center py-1.5 bg-blue-600 text-white">
              SPA
            </span>
            <a
              href={ssrPathFor(location.pathname)}
              className="flex-1 text-center py-1.5 bg-white text-gray-600 hover:bg-gray-50"
            >
              SSR
            </a>
          </div>
        </div>
      </nav>
      <main className="flex-1 p-6">
        <Outlet />
      </main>
    </div>
  );
}
