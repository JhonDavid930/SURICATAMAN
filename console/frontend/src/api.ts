export type Status = {
  installed: boolean;
  version: string;
  service_active: string;
  service_enabled: string;
  config_status: string;
  interface: string;
  rules_last_update: string;
  log_file: string;
};

export type Doctor = {
  failures: number;
  warnings: number;
  checks: Array<{ status: string; message: string }>;
};

export type EventRow = {
  timestamp: string;
  event_type: string;
  src_ip: string;
  src_port?: number;
  dest_ip: string;
  dest_port?: number;
  proto: string;
  signature: string;
  severity?: number;
  category: string;
  sid?: number;
};

export type Rule = {
  sid: number;
  action: string;
  proto: string;
  message: string;
  classtype: string;
  priority: number | null;
  enabled: boolean;
};

const API_BASE = import.meta.env.VITE_API_BASE || "http://127.0.0.1:8000";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, init);
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(detail || response.statusText);
  }
  return response.json() as Promise<T>;
}

export const api = {
  status: () => request<Status>("/api/status"),
  doctor: () => request<Doctor>("/api/doctor"),
  events: (params: URLSearchParams) => request<{ events: EventRow[] }>(`/api/events?${params}`),
  rules: (params: URLSearchParams) => request<{ rules: Rule[] }>(`/api/rules?${params}`),
  enableRule: (sid: number) => request(`/api/rules/${sid}/enable`, { method: "POST" }),
  disableRule: (sid: number) => request(`/api/rules/${sid}/disable`, { method: "POST" }),
  updateRules: () => request("/api/update-rules", { method: "POST" }),
  restart: () => request("/api/restart", { method: "POST" }),
  supportBundle: () => request("/api/support-bundle", { method: "POST" }),
  healthCheck: () => request("/api/health-check", { method: "POST" })
};
