import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

// GoodFinds uses the 'goodfinds' schema (isolated from GoodGems 'wms').
// The 'goodfinds' schema must be added to Supabase API > Exposed schemas.
export const supabase = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
  db: { schema: 'goodfinds' }
});
