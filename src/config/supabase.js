import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.4';

const SUPABASE_URL = 'https://xubufcfhcdtrsrvuulxh.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_rbrh83jGHubDm-IlVP24DA_bH5kwpE1';

export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    flowType: 'pkce'
  }
});

export { SUPABASE_URL };
