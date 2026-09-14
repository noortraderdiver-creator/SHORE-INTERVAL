const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Whitelist of valid collections — prevents typos or abuse from writing
// to arbitrary "tables" in the shared records store.
const VALID_COLLECTIONS = [
  'listings', 'sites', 'shops', 'threads', 'bookings', 'messages', 'applications'
];

// These collections hold personal data (cert photos, email addresses,
// guest names and travel dates) — reading them requires the admin
// password, unlike public content like listings or forum threads.
const ADMIN_ONLY_READ_COLLECTIONS = ['applications', 'bookings', 'messages'];

function hashPassword(plain) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(plain, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

function rowToRecord(row) {
  const record = { id: row.id, ...row.data, status: row.status };
  // A password hash should never leave the server, under any circumstance —
  // not even to the admin dashboard.
  delete record.passwordHash;
  return record;
}

function isAdminAuthorized(req) {
  const configured = process.env.ADMIN_PASSWORD;
  if (!configured) return false;
  return req.headers['x-admin-key'] === configured;
}

module.exports = async (req, res) => {
  const { collection } = req.query;

  if (!VALID_COLLECTIONS.includes(collection)) {
    return res.status(404).json({ error: `Unknown collection "${collection}"` });
  }

  if (req.method === 'GET') {
    // Narrow exception: a member checking their own application status
    // only needs their own record, not the full admin list — this keeps
    // that self-service check working without requiring the admin password.
    if (collection === 'applications' && req.query.email && !isAdminAuthorized(req)) {
      const { data, error } = await supabase
        .from('records')
        .select('*')
        .eq('collection', collection)
        .order('created_at', { ascending: false });

      if (error) return res.status(500).json({ error: error.message });
      const mine = data.filter(
        r => (r.data.email || '').toLowerCase() === String(req.query.email).toLowerCase()
      );
      return res.status(200).json(mine.map(rowToRecord));
    }

    if (ADMIN_ONLY_READ_COLLECTIONS.includes(collection) && !isAdminAuthorized(req)) {
      return res.status(401).json({ error: 'Admin password required' });
    }

    const { data, error } = await supabase
      .from('records')
      .select('*')
      .eq('collection', collection)
      .order('created_at', { ascending: false });

    if (error) return res.status(500).json({ error: error.message });
    return res.status(200).json(data.map(rowToRecord));
  }

  if (req.method === 'POST') {
    const body = { ...req.body };
    const id = body.id || `${collection}-${Date.now()}`;
    const status = body.status ?? null;
    delete body.id;
    delete body.status;

    // Passwords are hashed here, server-side, and the plaintext is never
    // written to the database or sent back in any response.
    if (collection === 'applications' && typeof body.password === 'string') {
      body.passwordHash = hashPassword(body.password);
    }
    delete body.password;
    delete body.confirmPassword;

    const { data, error } = await supabase
      .from('records')
      .insert({ collection, id, data: body, status })
      .select()
      .single();

    if (error) return res.status(500).json({ error: error.message });
    return res.status(201).json(rowToRecord(data));
  }

  res.setHeader('Allow', ['GET', 'POST']);
  return res.status(405).json({ error: `Method ${req.method} not allowed` });
};
