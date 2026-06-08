<script>
import { onMount } from 'svelte';
import { supabase } from '$lib/supabase';
import { rupiah, angka, persen } from '$lib/format';

let suppliers = [];
let balls = [];
  let categories = [];
  let ballCodes = [];
  let ballNames = [];
let loading = true;
let saving = false;
let errorMsg = '';

const today = new Date().toISOString().slice(0, 10);

let form = {
ball_code: '',
ball_name: '',
category: '',
supplier_id: '',
buy_price: '',
shipping_cost: '',
buy_date: today
};


async function loadAll() {
loading = true;
errorMsg = '';
const [sRes, bRes, cRes, bcRes, bnRes] = await Promise.all([
supabase.from('suppliers').select('id, code, name').order('code'),
supabase.from('v_ball_economics').select('*').order('buy_date', { ascending: false }),
      supabase.from('categories').select('id, name').order('name'),
      supabase.from('ball_codes').select('id, code').order('code'),
      supabase.from('ball_names').select('id, name').order('name')
    ]);
if (sRes.error) errorMsg = sRes.error.message;
if (bRes.error) errorMsg = bRes.error.message;
suppliers = sRes.data ?? [];
balls = bRes.data ?? [];
    categories = cRes.data ?? [];
    ballCodes = bcRes.data ?? [];
    ballNames = bnRes.data ?? [];
loading = false;
}



async function saveBall() {
errorMsg = '';
if (!form.ball_code || !form.category || !form.buy_price) {
errorMsg = 'Ball code, kategori, dan harga beli wajib diisi.';
return;
}
saving = true;
const payload = {
ball_code: form.ball_code.trim(),
ball_name: form.ball_name.trim(),
category: form.category.trim(),
supplier_id: form.supplier_id || null,
buy_price: Number(form.buy_price),
shipping_cost: form.shipping_cost === '' ? 0 : Number(form.shipping_cost),
buy_date: form.buy_date || today,
status: 'ordered'
};
const { error } = await supabase.from('balls').insert(payload);
saving = false;
if (error) { errorMsg = error.message; return; }
form = { ball_code: '', ball_name: '', category: '', supplier_id: '', buy_price: '', shipping_cost: '', buy_date: today };
await rememberReferences();
    await loadAll();
}
  async function rememberReferences() {
    const cat = form.category.trim();
    const bc = form.ball_code.trim();
    const bn = form.ball_name.trim();
    const jobs = [];
    if (cat) jobs.push(supabase.from('categories').upsert({ name: cat }, { onConflict: 'name' }));
    if (bc) jobs.push(supabase.from('ball_codes').upsert({ code: bc }, { onConflict: 'code' }));
    if (bn) jobs.push(supabase.from('ball_names').upsert({ name: bn }, { onConflict: 'name' }));
    if (jobs.length) await Promise.all(jobs);
  }

  async function deleteBall(b) {
    if (!b || !b.id) return;
    const label = b.internal_code || b.ball_code || 'ball ini';
    if (!confirm(`Hapus ${label}? Data akan disembunyikan dari daftar.`)) return;
    errorMsg = "";
    const { error } = await supabase.from('balls').update({ deleted_at: new Date().toISOString() }).eq('id', b.id);
    if (error) { errorMsg = error.message; return; }
    await loadAll();
  }


onMount(loadAll);
</script>

<div class="space-y-6">
<h1 class="text-2xl font-bold">Purchasing</h1>

{#if errorMsg}
<div class="rounded border border-red-300 bg-red-50 text-red-700 px-3 py-2 text-sm">{errorMsg}</div>
{/if}

<section class="rounded-lg border border-gray-200 bg-white p-5 space-y-4">
<h2 class="font-semibold">Input Ball Baru</h2>
<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
<label class="text-sm">Ball Code
<input bind:value={form.ball_code} list="dl-ball-codes" placeholder="AOSP" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
</label>
<label class="text-sm">Nama Ball
<input bind:value={form.ball_name} list="dl-ball-names" placeholder="Bola Plastik" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
</label>
<label class="text-sm">Kategori
<input bind:value={form.category} list="dl-categories" placeholder="celana" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
</label>
<label class="text-sm">Supplier
<select bind:value={form.supplier_id} class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5">
<option value="">- pilih -</option>
{#each suppliers as s}
<option value={s.id}>{s.name || s.code}</option>
{/each}
</select>
</label>
<label class="text-sm">Tanggal Pembelian
<input type="date" bind:value={form.buy_date} class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
</label>
<label class="text-sm">Harga Beli (Rp)
<input type="number" bind:value={form.buy_price} placeholder="8500000" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
</label>
<label class="text-sm">Ongkir (Rp)
<input type="number" bind:value={form.shipping_cost} placeholder="0" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
</label>
</div>
<p class="text-xs text-gray-500">Qty (pcs &amp; reject) diisi nanti di halaman Receiving saat ball dibuka.</p>
<div>
<button onclick={saveBall} disabled={saving} class="rounded bg-emerald-600 text-white px-4 py-2 text-sm font-medium hover:bg-emerald-700 disabled:opacity-50">{saving ? 'Menyimpan...' : 'Simpan Ball'}</button>
</div>
      <datalist id="dl-ball-codes">
        {#each ballCodes as c}<option value={c.code}></option>{/each}
      </datalist>
      <datalist id="dl-ball-names">
        {#each ballNames as n}<option value={n.name}></option>{/each}
      </datalist>
      <datalist id="dl-categories">
        {#each categories as c}<option value={c.name}></option>{/each}
      </datalist>
    </section>

<section class="rounded-lg border border-gray-200 bg-white overflow-hidden">
<div class="px-5 py-3 border-b border-gray-200 font-semibold">Daftar Ball</div>
{#if loading}
<div class="p-5 text-sm text-gray-500">Memuat...</div>
{:else if balls.length === 0}
<div class="p-5 text-sm text-gray-500">Belum ada ball. Input di atas.</div>
{:else}
<div class="overflow-x-auto">
<table class="w-full text-sm">
<thead class="bg-gray-50 text-gray-600 text-left">
<tr>
<th class="px-4 py-2">Internal Code</th>
<th class="px-4 py-2">Ball</th>
<th class="px-4 py-2">Nama</th>
<th class="px-4 py-2">Kategori</th>
<th class="px-4 py-2">Seller</th>
<th class="px-4 py-2">Tanggal</th>
<th class="px-4 py-2 text-right">Harga Beli</th>
<th class="px-4 py-2 text-right">Ongkir</th>
<th class="px-4 py-2 text-right">Pcs</th>
<th class="px-4 py-2 text-right">Reject</th>
<th class="px-4 py-2 text-right">Modal/Pcs</th>
<th class="px-4 py-2 text-right">Reject %</th>
            <th class="px-4 py-2 text-right">Aksi</th>
          </tr>
</thead>
<tbody>
{#each balls as b}
<tr class="border-t border-gray-100">
<td class="px-4 py-2 font-mono text-xs">{b.internal_code ?? '-'}</td>
<td class="px-4 py-2 font-medium">{b.ball_code}</td>
<td class="px-4 py-2">{b.ball_name ?? '-'}</td>
<td class="px-4 py-2">{b.category}</td>
<td class="px-4 py-2">{b.supplier_code ?? '-'}</td>
<td class="px-4 py-2">{b.buy_date ?? '-'}</td>
<td class="px-4 py-2 text-right">{rupiah(b.buy_price)}</td>
<td class="px-4 py-2 text-right">{rupiah(b.shipping_cost)}</td>
<td class="px-4 py-2 text-right">{angka(b.qty_pcs)}</td>
<td class="px-4 py-2 text-right">{angka(b.qty_reject)}</td>
<td class="px-4 py-2 text-right font-semibold">{rupiah(b.modal_per_pcs)}</td>
<td class="px-4 py-2 text-right">{persen(b.reject_pct)}</td>
            <td class="px-4 py-2 text-right">
              <button onclick={() => deleteBall(b)} class="rounded border border-red-300 text-red-600 hover:bg-red-50 px-2 py-1 text-xs">Hapus</button>
            </td>
          </tr>
{/each}
</tbody>
</table>
</div>
{/if}
</section>
</div>
