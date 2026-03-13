import type { ShowSettingsResponse } from "../../types";

export function SsrSettings(settings: ShowSettingsResponse) {
  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold">Settings</h2>

      <dl className="grid grid-cols-2 gap-2 text-sm">
        <dt className="text-gray-500">Store Name</dt>
        <dd>{settings.storeName}</dd>
        <dt className="text-gray-500">Currency</dt>
        <dd>{settings.currency}</dd>
        <dt className="text-gray-500">Timezone</dt>
        <dd>{settings.timezone}</dd>
        <dt className="text-gray-500">Maintenance Mode</dt>
        <dd>{settings.maintenanceMode ? "On" : "Off"}</dd>
      </dl>
    </div>
  );
}
