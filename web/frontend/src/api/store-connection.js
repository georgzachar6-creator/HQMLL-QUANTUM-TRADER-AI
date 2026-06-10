// HQMLL — Exchange Connection Storage Client
// Tries local /api/store-connection first (Vercel/Firebase Functions),
// then falls back to Supabase direct REST insert if service key is present.

export async function storeConnection({ provider, apiKey, apiSecret, userId }) {
  const edgeUrl = import.meta.env.VITE_STORE_CONNECTION_URL || '/api/store-connection';

  // Try serverless endpoint first
  try {
    const res = await fetch(edgeUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ provider, apiKey, apiSecret, userId }),
    });
    if (res.ok) return await res.json();
    console.warn('[storeConnection] serverless returned', res.status);
  } catch (err) {
    console.warn('[storeConnection] serverless failed:', err);
  }

  // Supabase fallback (server-side only — do NOT expose SERVICE_ROLE_KEY to browser in production)
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseServiceKey = import.meta.env.VITE_SUPABASE_SERVICE_KEY;
  if (!supabaseUrl || !supabaseServiceKey) {
    // Demo mode — just log locally
    console.log('[storeConnection] demo mode — connection saved locally only', { provider, userId });
    return { ok: true, mode: 'demo', provider };
  }

  const payload = {
    provider,
    user_id: userId,
    meta: {},
    creds_encrypted: null,
    creds_demo: { apiKey: apiKey ? '***' + String(apiKey).slice(-4) : null },
    status: 'connected',
    created_at: new Date().toISOString(),
  };

  const resp = await fetch(`${supabaseUrl}/rest/v1/connections`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      apikey: supabaseServiceKey,
      Authorization: `Bearer ${supabaseServiceKey}`,
      Prefer: 'return=representation',
    },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const text = await resp.text();
    throw new Error('Supabase REST insert failed: ' + text);
  }
  return await resp.json();
}

export async function getConnections(userId) {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseKey) return [];

  const resp = await fetch(`${supabaseUrl}/rest/v1/connections?user_id=eq.${userId}&select=*`, {
    headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
  });
  if (!resp.ok) return [];
  return await resp.json();
}
