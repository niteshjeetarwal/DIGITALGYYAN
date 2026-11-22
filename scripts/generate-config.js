#!/usr/bin/env node
/*
 * Generates admin-config.js from Netlify environment variables at build time.
 *
 * Only the PUBLIC Supabase client settings are written:
 *   SUPABASE_URL       – Supabase project URL
 *   SUPABASE_ANON_KEY  – publishable / legacy anon key (never service_role)
 *
 * Missing variables do not fail the build; the site still deploys and the
 * admin/resources pages show a "setup required" message until they are set.
 */
const fs = require('fs');
const path = require('path');

const url = (process.env.SUPABASE_URL || '').trim();
const anonKey = (process.env.SUPABASE_ANON_KEY || '').trim();

if (/service_role|sb_secret_/i.test(anonKey)) {
  console.error('ERROR: SUPABASE_ANON_KEY looks like a secret/service_role key. Use the public publishable or anon key instead.');
  process.exit(1);
}

const config = { url, anonKey };
const output =
  '/* Generated during Netlify build. Contains only the public Supabase client key. */\n' +
  'window.DG_SUPABASE_CONFIG = ' + JSON.stringify(config, null, 2) + ';\n';

const outFile = path.join(__dirname, '..', 'admin-config.js');
fs.writeFileSync(outFile, output);

if (!url || !anonKey) {
  console.warn('WARNING: SUPABASE_URL and/or SUPABASE_ANON_KEY are not set. admin-config.js was generated with empty values; the admin panel and resources page will show a setup message until they are configured.');
} else {
  console.log('admin-config.js generated with Supabase configuration.');
}
