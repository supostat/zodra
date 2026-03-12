import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useSettings, useUpdateSettings } from "../../hooks/use_settings";
import { UpdateSettingsParamsSchema } from "../../types/schemas";
import { ErrorMessage } from "../../components/error_message";
import { FieldError } from "../../components/field_error";
import type { UpdateSettingsParams } from "../../types/types";

interface Settings {
  storeName: string;
  currency: string;
  timezone: string;
  maintenanceMode: boolean;
}

export function SettingsPage() {
  const { data, isLoading, error } = useSettings();
  const updateSettings = useUpdateSettings();
  const [editing, setEditing] = useState(false);

  const settings = data?.data as Settings | undefined;

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<UpdateSettingsParams>({
    resolver: zodResolver(UpdateSettingsParamsSchema),
    values: settings ? {
      storeName: settings.storeName,
      currency: settings.currency,
      timezone: settings.timezone,
      maintenanceMode: settings.maintenanceMode,
    } : undefined,
  });

  if (isLoading) return <p>Loading...</p>;
  if (error) return <ErrorMessage error={error} />;
  if (!settings) return <p>No settings found</p>;

  function onSubmit(formData: UpdateSettingsParams) {
    updateSettings.mutate(formData, {
      onSuccess: () => setEditing(false),
    });
  }

  if (!editing) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Settings</h2>
          <button
            onClick={() => setEditing(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Edit
          </button>
        </div>

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

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">Edit Settings</h2>
      </div>

      <ErrorMessage error={updateSettings.error} />

      <div>
        <label className="block text-sm font-medium">Store Name</label>
        <input {...register("storeName")} className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.storeName?.message} />
      </div>

      <div>
        <label className="block text-sm font-medium">Currency</label>
        <input {...register("currency")} maxLength={3} className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.currency?.message} />
      </div>

      <div>
        <label className="block text-sm font-medium">Timezone</label>
        <input {...register("timezone")} className="border rounded px-3 py-1.5 w-full" />
        <FieldError message={errors.timezone?.message} />
      </div>

      <div className="flex items-center gap-2">
        <input {...register("maintenanceMode")} type="checkbox" />
        <label className="text-sm">Maintenance Mode</label>
      </div>

      <div className="flex gap-2">
        <button type="submit" disabled={updateSettings.isPending}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50">
          {updateSettings.isPending ? "Saving..." : "Save"}
        </button>
        <button type="button" onClick={() => { setEditing(false); reset(); }}
                className="px-4 py-2 border rounded hover:bg-gray-50">
          Cancel
        </button>
      </div>
    </form>
  );
}
