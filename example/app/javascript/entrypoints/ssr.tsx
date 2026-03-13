import { createRoot } from "react-dom/client";
import { SsrDashboard } from "../pages/ssr/ssr_dashboard";
import { SsrProductsList } from "../pages/ssr/ssr_products_list";
import { SsrProductDetail } from "../pages/ssr/ssr_product_detail";
import { SsrOrdersList } from "../pages/ssr/ssr_orders_list";
import { SsrOrderDetail } from "../pages/ssr/ssr_order_detail";
import { SsrSettings } from "../pages/ssr/ssr_settings";
import "../application.css";

const COMPONENTS: Record<string, React.ComponentType<any>> = {
  SsrDashboard,
  SsrProductsList,
  SsrProductDetail,
  SsrOrdersList,
  SsrOrderDetail,
  SsrSettings,
};

document.querySelectorAll<HTMLElement>("[data-react-component]").forEach((element) => {
  const name = element.dataset.reactComponent!;
  const props = JSON.parse(element.dataset.reactProps || "{}");
  const Component = COMPONENTS[name];

  if (Component) {
    createRoot(element).render(<Component {...props} />);
  }
});
