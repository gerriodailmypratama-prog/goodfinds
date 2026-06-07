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
            <th class="px-4 py-2">Seller</th>
            <th class="px-4 py-2">Tanggal</th>
            <th class="px-4 py-2">Harga Beli</th>
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
              <td class="px-4 py-2">{b.supplier_code ?? '-'}</td>
              <td class="px-4 py-2">{b.buy_date}</td>
              <td class="px-4 py-2">{rupiah(b.buy_price)}</td>
              <td class="px-4 py-2">
                <input type="number" min="0" bind:value={inputs[b.id].qty_pcs} placeholder="475" class="w-24 rounded border border-[#333] bg-[#0a0a0a] px-2 py-1.5" />
              </td>
              <td class="px-4 py-2">
                <input type="number" min="0" bind:value={inputs[b.id].qty_reject} placeholder="0" class="w-24 rounded border border-[#333] bg-[#0a0a0a] px-2 py-1.5" />
              </td>
              <td class="px-4 py-2">
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
