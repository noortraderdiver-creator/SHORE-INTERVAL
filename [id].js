const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const VALID_COLLECTIONS = [
  'listings', 'sites', 'shops', 'threads', 'bookings', 'messages', 'applications'
];

function rowToRecord(row) {
  return { id: row.id, ...row.data, status: row.status };
}

module.exports = async (req, res) => {
  const { collection, id } = req.query;

  if (!VALID_COLLECTIONS.includes(collection)) {
    return res.status(404).json({ error: `Unknown collection "${collection}"` });
  }

  if (req.method === 'PATCH') {
    // Merge the patch into the existing data (partial update), and update
    // status separately if it was included.
    const { data: existing, error: fetchErr } = await supabase
      .from('records')
      .select('*')
      .eq('collection', collection)
      .eq('id', id)
      .single();

    if (fetchErr || !existing) return res.status(404).json({ error: 'Not found' });

    const patch = { ...req.body };
    const status = 'status' in patch ? patch.status : existing.status;
    delete patch.status;
    delete patch.id;

    const mergedData = { ...existing.data, ...patch };

    const { data, error } = await supabase
      .from('records')
      .update({ data: mergedData, status })
      .eq('collection', collection)
      .eq('id', id)
      .select()
      .single();

    if (error) return res.status(500).json({ error: error.message });
    return res.status(200).json(rowToRecord(data));
  }

  if (req.method === 'DELETE') {
    const { error } = await supabase
      .from('records')
      .delete()
      .eq('collection', collection)
      .eq('id', id);

    if (error) return res.status(500).json({ error: error.message });
    return res.status(200).json({ deleted: true });
  }

  res.setHeader('Allow', ['PATCH', 'DELETE']);
  return res.status(405).json({ error: `Method ${req.method} not allowed` });
};
