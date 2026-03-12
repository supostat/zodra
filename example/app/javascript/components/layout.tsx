import { NavLink, Outlet } from "react-router";

const NAV_ITEMS = [
  { to: "/products", label: "Products" },
  { to: "/orders", label: "Orders" },
  { to: "/settings", label: "Settings" },
];

export function Layout() {
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
      </nav>
      <main className="flex-1 p-6">
        <Outlet />
      </main>
    </div>
  );
}
