<script>
import { onMount } from 'svelte';
import { supabase } from '$lib/supabase';
import { rupiah, angka, persen } from '$lib/format';

let balls = [];
let received = [];
let loading = true;
let errorMsg = '';

const today = new Date().toISOString().slice(0, 10);

// per-row receiving input state keyed by ball id
let inputs = {};
let savingId = null;

async function loadAll() {
  loading = true;
  errorMsg = '';
  const { data, error } = await supabase
    .from('v_ball_economics')
    .select('*')
    .order('buy_date', { ascending: false });
  loading = false;
  if (error) { errorMsg = error.message; return; }
  const rows = data ?? [];
  balls = rows.filter((b) => b.status === 'ordered');
  received = rows.filter((b) => b.status === 'opened');
  // seed inputs for pending balls
  const next = {};
  for (const b of balls) {
    next[b.id] = inputs[b.id] ?? { qty_pcs: '', qty_reject: '' };
  }
  inputs = next;
}

async function receiveBall(b) {
  errorMsg = '';
  const inp = inputs[b.id] ?? {};
  if (inp.qty_pcs === '' || inp.qty_pcs === undefined || inp.qty_pcs === null) {
    errorMsg = 'Qty Pcs wajib diisi untuk ' + (b.internal_code ?? b.ball_code);
    return;
  }
  savingId = b.id;
  const payload = {
    qty_pcs: Number(inp.qty_pcs),
    qty_reject: inp.qty_reject === '' || inp.qty_reject == null ? 0 : Number(inp.qty_reject),
    opened_at: today,
    status: 'opened'
  };
  const { error } = await supabase.from('balls').update(payload).eq('id', b.id);
  savingId = null;
  if (error) { errorMsg = error.message; return; }
  await loadAll();
}


    function printLabel(b) {
    const code = b.internal_code || '';
    if (!code) { errorMsg = 'Ball ini belum punya internal code.'; return; }
    const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    const ball = esc(b.ball_code || '');
    const nama = esc(b.ball_name || '');
    const kat = esc(b.category || '');
    const w = window.open('', '_blank', 'width=600,height=400');
    if (!w) { errorMsg = 'Popup diblokir browser. Izinkan popup untuk cetak label.'; return; }
    w.document.write(`<!doctype html><html><head><meta charset="utf-8"><title>Label ${esc(code)}<\/title>
<script src="https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.js"><\/script>
<style>
  @page { size: 150mm 100mm; margin: 0; }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  .label { width: 150mm; height: 100mm; padding: 6mm; display: flex; flex-direction: column; align-items: center; justify-content: center; font-family: Arial, Helvetica, sans-serif; }
  .ball { font-size: 30px; font-weight: 700; margin-bottom: 2mm; text-align: center; }
  .meta { font-size: 15px; color: #333; margin-bottom: 4mm; text-align: center; }
  #qr { width: 55mm; height: 55mm; display: flex; align-items: center; justify-content: center; }
  #qr svg { width: 100%; height: 100%; }
  .code { font-size: 16px; letter-spacing: 1px; margin-top: 3mm; font-family: monospace; }
  @media print { .noprint { display: none; } }
  .noprint { margin-top: 8px; }
<\/style><\/head>
<body><div class="label">
  <div class="ball">${ball}<\/div>
  <div class="meta">${nama ? nama + ' \u00b7 ' : ''}${kat}<\/div>
  <div id="qr"><\/div>
  <div class="code">${esc(code)}<\/div>
<\/div>
<div class="noprint" style="text-align:center"><button onclick="window.print()">Cetak<\/button><\/div>
<script>
  var CODE = ${JSON.stringify(code)};
  var printed = false;
  function render(){
    var el = document.getElementById('qr');
    try {
      var qr = qrcode(0, 'M');
      qr.addData(CODE);
      qr.make();
      el.innerHTML = qr.createSvgTag({ scalable: true });
    } catch (e) {
      el.innerHTML = '<div style=`"font-family:monospace;font-size:20px"`>' + CODE + '<\/div>';
    }
  }
  function go(){ if (printed) return; printed = true; render(); setTimeout(function(){ window.focus(); window.print(); }, 400); }
  if (typeof qrcode !== 'undefined') { go(); } else { window.addEventListener('load', go); setTimeout(go, 1500); }
<\/script>
<\/body><\/html>`);
    w.document.close();
  }

onMount(loadAll);
</script>

<h1 class="text-xl font-bold mb-1">Receiving</h1>
<p class="text-sm text-gray-400 mb-5">Input qty hasil sortir saat ball dibuka. Ball pindah ke <span class="text-green-400">Sudah Diterima</span> setelah disimpan.</p>

{#if errorMsg}
  <div class="mb-4 rounded border border-red-500/40 bg-red-500/10 px-3 py-2 text-sm text-red-300">{errorMsg}</div>
{/if}

<section class="rounded-lg border border-[#2a2a2a] bg-[#111] overflow-hidden mb-8">
  <div class="px-4 py-3 border-b border-[#2a2a2a] flex items-center justify-between">
    <h2 class="font-semibold">Menunggu Diterima</h2>
    <span class="text-xs text-gray-500">{balls.length} ball</span>
  </div>
  {#if loading}
    <p class="px-4 py-6 text-sm text-gray-500">Memuat...</p>
  {:else if balls.length === 0}
    <p class="px-4 py-6 text-sm text-gray-500">Tidak ada ball yang menunggu. Semua sudah diterima.</p>
  {:else}
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-[#0a0a0a] text-gray-400 text-left">
          <tr>
            <th class="px-4 py-2">Internal Code</th>
            <th class="px-4 py-2">Ball</th>
            <th class="px-4 py-2">Nama</th>
            <th class="px-4 py-2">Kategori</th>
            <th class="px-4 py-2">Tanggal</th>
            <th class="px-4 py-2 w-28">Qty Pcs</th>
            <th class="px-4 py-2 w-28">Qty Reject</th>
            <th class="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {#each balls as b (b.id)}
            <tr class="border-t border-[#1f1f1f]">
              <td class="px-4 py-2 font-mono text-xs">{b.internal_code ?? '-'}</td>
              <td class="px-4 py-2 font-medium">{b.ball_code}</td>
              <td class="px-4 py-2">{b.ball_name ?? '-'}</td>
              <td class="px-4 py-2">{b.category}</td>
              <td class="px-4 py-2">{b.buy_date}</td>
              <td class="px-4 py-2">
                <input type="number" min="0" bind:value={inputs[b.id].qty_pcs} placeholder="475" class="w-24 rounded border border-[#333] bg-[#0a0a0a] px-2 py-1.5" />
              </td>
              <td class="px-4 py-2">
                <input type="number" min="0" bind:value={inputs[b.id].qty_reject} placeholder="0" class="w-24 rounded border border-[#333] bg-[#0a0a0a] px-2 py-1.5" />
              </td>
              <td class="px-4 py-2">
                <button on:click={() => printLabel(b)} class="rounded bg-indigo-600 text-white px-3 py-1.5 text-xs font-medium hover:bg-indigo-700 whitespace-nowrap mr-2">Label</button>
                <button on:click={() => receiveBall(b)} disabled={savingId === b.id} class="rounded bg-emerald-600 text-white px-3 py-1.5 text-xs font-medium hover:bg-emerald-700 disabled:opacity-50 whitespace-nowrap">{savingId === b.id ? 'Menyimpan...' : 'Terima'}</button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</section>

<section class="rounded-lg border border-[#2a2a2a] bg-[#111] overflow-hidden">
  <div class="px-4 py-3 border-b border-[#2a2a2a] flex items-center justify-between">
    <h2 class="font-semibold">Sudah Diterima</h2>
    <span class="text-xs text-gray-500">{received.length} ball</span>
  </div>
  {#if received.length === 0}
    <p class="px-4 py-6 text-sm text-gray-500">Belum ada ball yang diterima.</p>
  {:else}
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-[#0a0a0a] text-gray-400 text-left">
          <tr>
            <th class="px-4 py-2">Internal Code</th>
            <th class="px-4 py-2">Ball</th>
            <th class="px-4 py-2">Nama</th>
            <th class="px-4 py-2">Diterima</th>
            <th class="px-4 py-2">Pcs</th>
            <th class="px-4 py-2">Reject</th>
            <th class="px-4 py-2">Total</th>
            <th class="px-4 py-2">Modal/Pcs</th>
            <th class="px-4 py-2">Reject %</th>
          </tr>
        </thead>
        <tbody>
          {#each received as b (b.id)}
            <tr class="border-t border-[#1f1f1f]">
              <td class="px-4 py-2 font-mono text-xs">{b.internal_code ?? '-'}</td>
              <td class="px-4 py-2 font-medium">{b.ball_code}</td>
              <td class="px-4 py-2">{b.ball_name ?? '-'}</td>
              <td class="px-4 py-2">{b.opened_at ?? '-'}</td>
              <td class="px-4 py-2">{angka(b.qty_pcs)}</td>
              <td class="px-4 py-2">{angka(b.qty_reject)}</td>
              <td class="px-4 py-2">{angka(b.qty_total)}</td>
              <td class="px-4 py-2">{rupiah(b.modal_per_pcs)}</td>
              <td class="px-4 py-2">{persen(b.reject_pct)}</td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</section>
