const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Whitelist of valid collections — prevents typos or abuse from writing
// to arbitrary "tables" in the shared records store.
const VALID_COLLECTIONS = [
  'listings', 'sites', 'shops', 'threads', 'bookings', 'messages', 'applications'
];

function rowToRecord(row) {
  return { id: row.id, ...row.data, status: row.status };
}

module.exports = async (req, res) => {
  const { collection } = req.query;

  if (!VALID_COLLECTIONS.includes(collection)) {
    return res.status(404).json({ error: `Unknown collection "${collection}"` });
  }

  if (req.method === 'GET') {
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
