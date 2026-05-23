import { Activity, FileArchive, HeartPulse, RefreshCw, RotateCw, Search, ShieldCheck, Siren } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { api, Doctor, EventRow, Rule, Status } from "./api";

type Tab = "dashboard" | "events" | "rules";

function StatusPill({ value }: { value: string }) {
  const healthy = ["active", "enabled", "valida"].some((item) => value.toLowerCase().includes(item));
  return <span className={healthy ? "pill good" : "pill warn"}>{value || "desconocido"}</span>;
}

function useAsync<T>(loader: () => Promise<T>, deps: unknown[]) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const reload = () => {
    setLoading(true);
    setError("");
    loader()
      .then(setData)
      .catch((err) => setError(err instanceof Error ? err.message : "Error desconocido"))
      .finally(() => setLoading(false));
  };
  useEffect(reload, deps);
  return { data, error, loading, reload };
}

function Dashboard() {
  const status = useAsync<Status>(() => api.status(), []);
  const doctor = useAsync<Doctor>(() => api.doctor(), []);
  const [action, setAction] = useState("");

  async function runAction(label: string, task: () => Promise<unknown>) {
    if (!window.confirm(`Ejecutar ${label}?`)) return;
    setAction(`Ejecutando ${label}...`);
    try {
      await task();
      setAction(`${label} completado.`);
      status.reload();
      doctor.reload();
    } catch (err) {
      setAction(err instanceof Error ? err.message : "Accion fallida");
    }
  }

  return (
    <section className="panel">
      <div className="panelHeader">
        <h2>Dashboard operativo</h2>
        <button className="iconButton" onClick={() => { status.reload(); doctor.reload(); }} title="Actualizar">
          <RefreshCw size={18} />
        </button>
      </div>
      {status.error && <div className="error">{status.error}</div>}
      <div className="metrics">
        <div><span>Suricata</span><strong>{status.data?.installed ? "Instalado" : "No instalado"}</strong></div>
        <div><span>Servicio</span><StatusPill value={status.data?.service_active || ""} /></div>
        <div><span>Arranque</span><StatusPill value={status.data?.service_enabled || ""} /></div>
        <div><span>Configuracion</span><StatusPill value={status.data?.config_status || ""} /></div>
      </div>
      <div className="details">
        <p><b>Version:</b> {status.data?.version || "Cargando..."}</p>
        <p><b>Interfaz:</b> {status.data?.interface || "-"}</p>
        <p><b>Reglas:</b> {status.data?.rules_last_update || "-"}</p>
        <p><b>Log:</b> {status.data?.log_file || "-"}</p>
      </div>
      <div className="doctor">
        <h3>Doctor</h3>
        <p>{doctor.data ? `${doctor.data.failures} fallos, ${doctor.data.warnings} advertencias` : "Cargando diagnostico..."}</p>
        <ul>
          {(doctor.data?.checks || []).slice(0, 6).map((check, index) => (
            <li key={`${check.status}-${index}`}><span className={`dot ${check.status.toLowerCase()}`} />{check.message}</li>
          ))}
        </ul>
      </div>
      <div className="actions">
        <button onClick={() => runAction("health-check", api.healthCheck)}><HeartPulse size={16} /> Health-check</button>
        <button onClick={() => runAction("actualizar reglas", api.updateRules)}><RotateCw size={16} /> Actualizar reglas</button>
        <button onClick={() => runAction("reiniciar Suricata", api.restart)}><ShieldCheck size={16} /> Reiniciar</button>
        <button onClick={() => runAction("support-bundle", api.supportBundle)}><FileArchive size={16} /> Bundle</button>
      </div>
      {action && <div className="notice">{action}</div>}
    </section>
  );
}

function Events() {
  const [type, setType] = useState("");
  const [src, setSrc] = useState("");
  const [dst, setDst] = useState("");
  const [limit, setLimit] = useState(50);
  const params = useMemo(() => {
    const search = new URLSearchParams();
    if (type) search.set("type", type);
    if (src) search.set("src", src);
    if (dst) search.set("dst", dst);
    search.set("limit", String(limit));
    return search;
  }, [type, src, dst, limit]);
  const events = useAsync<{ events: EventRow[] }>(() => api.events(params), [params.toString()]);

  return (
    <section className="panel">
      <div className="panelHeader"><h2>Eventos</h2><button className="iconButton" onClick={events.reload}><RefreshCw size={18} /></button></div>
      <div className="filters">
        <select value={type} onChange={(event) => setType(event.target.value)}>
          <option value="">Todos</option><option value="alert">Alertas</option><option value="ssh">SSH</option><option value="dns">DNS</option>
        </select>
        <input placeholder="Origen" value={src} onChange={(event) => setSrc(event.target.value)} />
        <input placeholder="Destino" value={dst} onChange={(event) => setDst(event.target.value)} />
        <input type="number" min="1" max="500" value={limit} onChange={(event) => setLimit(Number(event.target.value))} />
        <button onClick={() => navigator.clipboard.writeText(JSON.stringify(events.data?.events || [], null, 2))}>Exportar JSON</button>
      </div>
      {events.error && <div className="error">{events.error}</div>}
      <div className="tableWrap">
        <table>
          <thead><tr><th>Fecha</th><th>Tipo</th><th>Origen</th><th>Destino</th><th>Firma</th><th>Sev</th></tr></thead>
          <tbody>
            {(events.data?.events || []).map((event, index) => (
              <tr key={`${event.timestamp}-${index}`}>
                <td>{event.timestamp}</td><td>{event.event_type}</td><td>{event.src_ip}</td><td>{event.dest_ip}</td><td>{event.signature || "-"}</td><td>{event.severity || "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function Rules() {
  const [query, setQuery] = useState("");
  const params = useMemo(() => {
    const search = new URLSearchParams();
    if (query) search.set("query", query);
    search.set("limit", "250");
    return search;
  }, [query]);
  const rules = useAsync<{ rules: Rule[] }>(() => api.rules(params), [params.toString()]);

  async function toggle(rule: Rule) {
    const action = rule.enabled ? "deshabilitar" : "habilitar";
    if (!window.confirm(`${action} regla ${rule.sid}? Se creara backup y se validara Suricata.`)) return;
    if (rule.enabled) await api.disableRule(rule.sid);
    else await api.enableRule(rule.sid);
    rules.reload();
  }

  return (
    <section className="panel">
      <div className="panelHeader"><h2>Reglas</h2><button className="iconButton" onClick={rules.reload}><RefreshCw size={18} /></button></div>
      <div className="filters"><Search size={18} /><input placeholder="Buscar SID, texto, categoria o protocolo" value={query} onChange={(event) => setQuery(event.target.value)} /></div>
      {rules.error && <div className="error">{rules.error}</div>}
      <div className="tableWrap">
        <table>
          <thead><tr><th>SID</th><th>Accion</th><th>Proto</th><th>Mensaje</th><th>Categoria</th><th>Prioridad</th><th>Estado</th></tr></thead>
          <tbody>
            {(rules.data?.rules || []).map((rule) => (
              <tr key={rule.sid}>
                <td>{rule.sid}</td><td>{rule.action}</td><td>{rule.proto}</td><td>{rule.message}</td><td>{rule.classtype || "-"}</td><td>{rule.priority || "-"}</td>
                <td><button className={rule.enabled ? "small danger" : "small"} onClick={() => toggle(rule)}>{rule.enabled ? "Deshabilitar" : "Habilitar"}</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

export default function App() {
  const [tab, setTab] = useState<Tab>("dashboard");
  return (
    <main>
      <aside>
        <div className="brand"><Siren size={24} /><div><strong>SURICATAMAN</strong><span>Console v0.1</span></div></div>
        <nav>
          <button className={tab === "dashboard" ? "active" : ""} onClick={() => setTab("dashboard")}><Activity size={18} /> Dashboard</button>
          <button className={tab === "events" ? "active" : ""} onClick={() => setTab("events")}><Siren size={18} /> Eventos</button>
          <button className={tab === "rules" ? "active" : ""} onClick={() => setTab("rules")}><ShieldCheck size={18} /> Reglas</button>
        </nav>
      </aside>
      <section className="content">
        {tab === "dashboard" && <Dashboard />}
        {tab === "events" && <Events />}
        {tab === "rules" && <Rules />}
      </section>
    </main>
  );
}
