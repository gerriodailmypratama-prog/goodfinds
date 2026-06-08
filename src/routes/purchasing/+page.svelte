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


function printLabel(b) {
    const code = b.internal_code || ''
    if (!code) { errorMsg = 'Ball ini belum punya internal code.'; return }
    const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))
    const ball = esc(b.ball_code || '')
    const nama = esc(b.ball_name || '')
    const kat = esc(b.category || '')
    const w = window.open('', '_blank', 'width=600,height=400')
    if (!w) { errorMsg = 'Popup diblokir browser. Izinkan popup untuk cetak label.'; return }
    w.document.write(`<!doctype html><html><head><meta charset="utf-8"><title>Label ${esc(code)}</title>
<script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"><\/script>
<style>
  @page { size: 150mm 100mm; margin: 0; }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  .label { width: 150mm; height: 100mm; padding: 6mm; display: flex; flex-direction: column; align-items: center; justify-content: center; font-family: Arial, Helvetica, sans-serif; }
  .ball { font-size: 30px; font-weight: 700; margin-bottom: 2mm; text-align: center; }
  .meta { font-size: 15px; color: #333; margin-bottom: 4mm; text-align: center; }
  svg { width: 100%; max-width: 130mm; height: auto; }
  .code { font-size: 16px; letter-spacing: 1px; margin-top: 2mm; font-family: monospace; }
  @media print { .noprint { display: none; } }
  .noprint { margin-top: 8px; }
</style></head>
<body><div class="label">
  <div class="ball">${ball}</div>
  <div class="meta">${nama ? nama + ' &middot; ' : ''}${kat}</div>
  <svg id="bc"></svg>
  <div class="code">${esc(code)}</div>
</div>
<div class="noprint" style="text-align:center"><button onclick="window.print()">Cetak</button></div>
<script>
  function render(){ try { JsBarcode('#bc', ${JSON.stringify(code)}, { format: 'CODE128', width: 2, height: 80, displayValue: false, margin: 0 }); } catch(e){} }
  function go(){ render(); setTimeout(function(){ window.focus(); window.print(); }, 350); }
  if (window.JsBarcode) { go(); } else { window.addEventListener('load', go); }
<\/script>
</body></html>`)
    w.document.close()
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
              <button onclick={() => printLabel(b)} class="rounded border border-gray-300 text-gray-700 hover:bg-gray-50 px-2 py-1 text-xs mr-1">Label</button>
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
