import { createRoot } from "react-dom/client";
import { DashboardApp } from "../pages/admin/dashboard_app";
import "../application.css";

const COMPONENTS: Record<string, React.ComponentType<any>> = {
  DashboardApp,
};

document.querySelectorAll<HTMLElement>("[data-react-component]").forEach((element) => {
  const name = element.dataset.reactComponent!;
  const props = JSON.parse(element.dataset.reactProps || "{}");
  const Component = COMPONENTS[name];

  if (Component) {
    createRoot(element).render(<Component {...props} />);
  }
});
