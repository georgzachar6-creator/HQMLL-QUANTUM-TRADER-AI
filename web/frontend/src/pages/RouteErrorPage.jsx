import React from 'react';
import { Link, isRouteErrorResponse, useRouteError } from 'react-router-dom';

export default function RouteErrorPage() {
  const error = useRouteError();
  let title = 'Etwas ist schiefgelaufen';
  let message = 'Ein unbekannter Fehler ist aufgetreten.';
  let status = null;

  if (isRouteErrorResponse(error)) {
    status = error.status;
    title = `Fehler ${error.status}`;
    message = (error.data?.message) || error.statusText || message;
  } else if (error instanceof Error) {
    message = error.message;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100vh', gap: 16, padding: 24 }}>
      <div style={{ fontSize: 64 }}>⚛️</div>
      <div className="badge badge-red">{status ? `Error ${status}` : 'Error'}</div>
      <h1 style={{ fontSize: 24, color: 'var(--text-primary)' }}>{title}</h1>
      <p style={{ color: 'var(--text-secondary)', textAlign: 'center', maxWidth: 400 }}>{message}</p>
      <div style={{ display: 'flex', gap: 12 }}>
        <Link to="/dashboard" className="btn btn-primary">🏠 Dashboard</Link>
        <button className="btn btn-secondary" onClick={() => window.history.back()}>← Zurück</button>
      </div>
    </div>
  );
}
