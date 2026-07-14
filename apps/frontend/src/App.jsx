import { useEffect, useState } from 'react';

const REFRESH_INTERVAL_MS = 5000;
const EMPTY_FORM = { debtorIban: '', creditorIban: '', amount: '', currency: 'EUR' };
const EMPTY_FILTERS = { status: '', currency: '' };
const CURRENCIES = ['EUR', 'USD', 'GBP'];
const USERNAME_STORAGE_KEY = 'payment-orders-username';

async function fetchOrders(filters, username) {
  const params = new URLSearchParams();
  if (filters.status) params.set('status', filters.status);
  if (filters.currency) params.set('currency', filters.currency);
  const qs = params.toString();
  const response = await fetch(`/api/orders${qs ? `?${qs}` : ''}`, {
    headers: { 'X-Username': username },
  });
  if (!response.ok) throw new Error('Failed to load orders');
  return response.json();
}

async function fetchInfo() {
  const response = await fetch('/api/info');
  if (!response.ok) throw new Error('Failed to load info');
  return response.json();
}

async function createOrder(payload, username) {
  const response = await fetch('/api/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Username': username },
    body: JSON.stringify(payload),
  });
  const body = await response.json();
  if (!response.ok) {
    const error = new Error(body.message || 'Order creation failed');
    error.details = Array.isArray(body.details) ? body.details : [];
    throw error;
  }
  return body;
}

function StatusBadge({ status }) {
  const className = status === 'SETTLED' ? 'badge badge-settled' : 'badge badge-pending';
  return <span className={className}>{status}</span>;
}

function StatsRow({ orders }) {
  const pending = orders.filter((o) => o.status === 'PENDING').length;
  const settled = orders.filter((o) => o.status === 'SETTLED').length;
  return (
    <div className="stats-row">
      <div className="stat">
        <div className="stat-value">{orders.length}</div>
        <div className="stat-label">Orders shown</div>
      </div>
      <div className="stat">
        <div className="stat-value">{pending}</div>
        <div className="stat-label">Pending</div>
      </div>
      <div className="stat">
        <div className="stat-value">{settled}</div>
        <div className="stat-label">Settled</div>
      </div>
    </div>
  );
}

function LoginScreen({ onLogin }) {
  const [username, setUsername] = useState('');

  const handleSubmit = (event) => {
    event.preventDefault();
    const trimmed = username.trim();
    if (trimmed) onLogin(trimmed);
  };

  return (
    <div className="page login-page">
      <div className="card login-card">
        <h1>Mini Payment Orders</h1>
        <p>Connecte-toi pour créer et suivre tes propres ordres de virement.</p>
        <form onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="username">Nom d&apos;utilisateur</label>
            <input
              id="username"
              placeholder="ex: alice"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              required
            />
          </div>
          <button type="submit" className="btn-primary">
            Se connecter
          </button>
        </form>
        <p className="login-note">
          Démo : aucun mot de passe vérifié — ce nom sert uniquement à identifier tes ordres.
        </p>
      </div>
    </div>
  );
}

export default function App() {
  const [username, setUsername] = useState(() => localStorage.getItem(USERNAME_STORAGE_KEY) || '');
  const [orders, setOrders] = useState([]);
  const [form, setForm] = useState(EMPTY_FORM);
  const [formError, setFormError] = useState(null);
  const [info, setInfo] = useState(null);
  const [filters, setFilters] = useState(EMPTY_FILTERS);

  useEffect(() => {
    if (!username) return undefined;
    const reloadOrders = () => {
      fetchOrders(filters, username).then(setOrders).catch((err) => console.error(err));
    };
    reloadOrders();
    const interval = setInterval(reloadOrders, REFRESH_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [filters, username]);

  useEffect(() => {
    fetchInfo().then(setInfo).catch((err) => console.error(err));
  }, []);

  const handleLogin = (name) => {
    localStorage.setItem(USERNAME_STORAGE_KEY, name);
    setUsername(name);
  };

  const handleLogout = () => {
    localStorage.removeItem(USERNAME_STORAGE_KEY);
    setUsername('');
    setOrders([]);
    setForm(EMPTY_FORM);
    setFormError(null);
    setFilters(EMPTY_FILTERS);
  };

  const handleChange = (field) => (event) => {
    setForm({ ...form, [field]: event.target.value });
  };

  const handleFilterChange = (field) => (event) => {
    setFilters({ ...filters, [field]: event.target.value });
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setFormError(null);
    try {
      await createOrder({ ...form, amount: Number(form.amount) }, username);
      setForm(EMPTY_FORM);
      fetchOrders(filters, username).then(setOrders).catch((err) => console.error(err));
    } catch (err) {
      setFormError({ message: err.message, details: err.details || [] });
    }
  };

  if (!username) {
    return <LoginScreen onLogin={handleLogin} />;
  }

  return (
    <div className="page">
      <header className="page-header">
        <div className="page-header-row">
          <div>
            <h1>Mini Payment Orders</h1>
            <p>SG DevOps INTERVIEW — create fictitious transfer orders and track their settlement.</p>
          </div>
          <div className="session-info">
            <span>
              Connecté en tant que <strong>{username}</strong>
            </span>
            <button type="button" className="btn-link" onClick={handleLogout}>
              Se déconnecter
            </button>
          </div>
        </div>
      </header>

      <section className="card">
        <h2>New order</h2>
        <form onSubmit={handleSubmit}>
          <div className="form-grid">
            <div className="field">
              <label htmlFor="debtorIban">Debtor IBAN</label>
              <input
                id="debtorIban"
                placeholder="FR7630006000011234567890189"
                value={form.debtorIban}
                onChange={handleChange('debtorIban')}
                required
              />
              <p className="field-hint">2 letters + 2 digits + 11-30 letters/digits, e.g. the placeholder above</p>
            </div>
            <div className="field">
              <label htmlFor="creditorIban">Creditor IBAN</label>
              <input
                id="creditorIban"
                placeholder="DE89370400440532013000"
                value={form.creditorIban}
                onChange={handleChange('creditorIban')}
                required
              />
              <p className="field-hint">2 letters + 2 digits + 11-30 letters/digits, e.g. the placeholder above</p>
            </div>
            <div className="field">
              <label htmlFor="amount">Amount</label>
              <input
                id="amount"
                type="number"
                step="0.01"
                placeholder="100.00"
                value={form.amount}
                onChange={handleChange('amount')}
                required
              />
              <p className="field-hint">Positive number — e.g. 100.00</p>
            </div>
            <div className="field">
              <label htmlFor="currency">Currency</label>
              <input
                id="currency"
                placeholder="EUR"
                value={form.currency}
                onChange={handleChange('currency')}
                maxLength={3}
                required
              />
              <p className="field-hint">3 uppercase letters, real currency — e.g. EUR, USD, GBP</p>
            </div>
          </div>
          <button type="submit" className="btn-primary form-submit">
            Create order
          </button>
          {formError && (
            <div className="form-error">
              <p className="form-error-title">{formError.message}</p>
              {formError.details.length > 0 && (
                <ul>
                  {formError.details.map((detail) => (
                    <li key={detail}>{detail}</li>
                  ))}
                </ul>
              )}
            </div>
          )}
        </form>
      </section>

      <section className="card">
        <h2>Order history</h2>

        <StatsRow orders={orders} />

        <div className="filters-row">
          <div className="field">
            <label htmlFor="statusFilter">Status</label>
            <select id="statusFilter" value={filters.status} onChange={handleFilterChange('status')}>
              <option value="">All</option>
              <option value="PENDING">Pending</option>
              <option value="SETTLED">Settled</option>
            </select>
          </div>
          <div className="field">
            <label htmlFor="currencyFilter">Currency</label>
            <select id="currencyFilter" value={filters.currency} onChange={handleFilterChange('currency')}>
              <option value="">All</option>
              {CURRENCIES.map((currency) => (
                <option key={currency} value={currency}>
                  {currency}
                </option>
              ))}
            </select>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Reference</th>
              <th>Debtor</th>
              <th>Creditor</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id}>
                <td className="mono">{order.reference}</td>
                <td className="mono">{order.debtorIban}</td>
                <td className="mono">{order.creditorIban}</td>
                <td className="mono">
                  {order.amount} {order.currency}
                </td>
                <td>
                  <StatusBadge status={order.status} />
                </td>
              </tr>
            ))}
            {orders.length === 0 && (
              <tr className="empty-row">
                <td colSpan={5}>No orders match the current filters</td>
              </tr>
            )}
          </tbody>
        </table>
      </section>

      <footer className="page-footer">
        {info ? `v${info.version} · ${info.environment} · ${info.message}` : 'Loading info...'}
      </footer>
    </div>
  );
}
