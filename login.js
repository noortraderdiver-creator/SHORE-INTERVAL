const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

function verifyPassword(plain, stored) {
  if (!stored || typeof stored !== 'string' || !stored.includes(':')) return false;
  const [salt, hashHex] = stored.split(':');
  const candidateHex = crypto.scryptSync(plain, salt, 64).toString('hex');
  const a = Buffer.from(candidateHex, 'hex');
  const b = Buffer.from(hashHex, 'hex');
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function sanitize(row) {
  const record = { id: row.id, ...row.data, status: row.status };
  delete record.passwordHash;
  return record;
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: `Method ${req.method} not allowed` });
  }

  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  const { data, error } = await supabase
    .from('records')
    .select('*')
    .eq('collection', 'applications')
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });

  const candidates = data.filter(
    r => (r.data.email || '').toLowerCase() === String(email).toLowerCase()
  );

  for (const row of candidates) {
    if (verifyPassword(password, row.data.passwordHash)) {
      return res.status(200).json(sanitize(row));
    }
  }

  // Deliberately vague — never reveal whether the email exists at all.
  return res.status(401).json({ error: 'Incorrect email or password.' });
};
