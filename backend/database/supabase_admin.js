const config = require('../config');

class SupabaseAdmin {
  constructor() {
    this.url = config.supabase.url;
    this.key = config.supabase.serviceRoleKey;
  }

  get isConfigured() {
    return Boolean(this.url && this.key);
  }

  _headers(extra = {}) {
    return {
      'apikey': this.key,
      'Authorization': `Bearer ${this.key}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
      ...extra
    };
  }

  async select(table, queryParams = '') {
    if (!this.isConfigured) throw new Error('Supabase serviceRoleKey is not configured.');
    const q = queryParams ? (queryParams.startsWith('?') ? queryParams : `?${queryParams}`) : '';
    const res = await fetch(`${this.url}/rest/v1/${table}${q}`, {
      method: 'GET',
      headers: this._headers({ 'Range': '0-999' })
    });
    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`[SupabaseAdmin] Select ${table} failed (${res.status}): ${errText}`);
    }
    return await res.json();
  }

  async insert(table, data) {
    if (!this.isConfigured) throw new Error('Supabase serviceRoleKey is not configured.');
    const res = await fetch(`${this.url}/rest/v1/${table}`, {
      method: 'POST',
      headers: this._headers(),
      body: JSON.stringify(data)
    });
    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`[SupabaseAdmin] Insert into ${table} failed (${res.status}): ${errText}`);
    }
    return await res.json();
  }

  async update(table, data, matchQuery) {
    if (!this.isConfigured) throw new Error('Supabase serviceRoleKey is not configured.');
    const q = matchQuery.startsWith('?') ? matchQuery : `?${matchQuery}`;
    const res = await fetch(`${this.url}/rest/v1/${table}${q}`, {
      method: 'PATCH',
      headers: this._headers(),
      body: JSON.stringify(data)
    });
    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`[SupabaseAdmin] Update ${table} failed (${res.status}): ${errText}`);
    }
    return await res.json();
  }

  async delete(table, matchQuery) {
    if (!this.isConfigured) throw new Error('Supabase serviceRoleKey is not configured.');
    const q = matchQuery.startsWith('?') ? matchQuery : `?${matchQuery}`;
    const res = await fetch(`${this.url}/rest/v1/${table}${q}`, {
      method: 'DELETE',
      headers: this._headers()
    });
    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`[SupabaseAdmin] Delete from ${table} failed (${res.status}): ${errText}`);
    }
    return await res.json();
  }
}

module.exports = new SupabaseAdmin();
