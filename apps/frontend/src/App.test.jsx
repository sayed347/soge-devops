import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import App from './App.jsx';

describe('App', () => {
  beforeEach(() => {
    localStorage.clear();

    global.fetch = vi.fn((url) => {
      if (url === '/api/orders') {
        return Promise.resolve({
          ok: true,
          json: () =>
            Promise.resolve([
              {
                id: '1',
                reference: 'PO-ABCD1234',
                debtorIban: 'FR7630006000011234567890189',
                creditorIban: 'DE89370400440532013000',
                amount: 100,
                currency: 'EUR',
                status: 'PENDING',
                createdBy: 'alice',
              },
            ]),
        });
      }
      if (url === '/api/info') {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ version: '0.1.0', environment: 'local', message: 'local' }),
        });
      }
      return Promise.reject(new Error(`Unexpected fetch url: ${url}`));
    });
  });

  it('shows a login screen before any orders are loaded', () => {
    render(<App />);

    expect(screen.getByLabelText(/nom d'utilisateur/i)).toBeInTheDocument();
    expect(screen.queryByText('PO-ABCD1234')).not.toBeInTheDocument();
  });

  it('logs in then renders the orders table scoped to that user', async () => {
    render(<App />);

    fireEvent.change(screen.getByLabelText(/nom d'utilisateur/i), { target: { value: 'alice' } });
    fireEvent.click(screen.getByRole('button', { name: /se connecter/i }));

    expect(await screen.findByText('PO-ABCD1234')).toBeInTheDocument();
    expect(screen.getByText('PENDING')).toBeInTheDocument();
    expect(screen.getByText('alice')).toBeInTheDocument();

    const ordersCall = global.fetch.mock.calls.find(([url]) => url === '/api/orders');
    expect(ordersCall[1].headers['X-Username']).toBe('alice');
  });
});
