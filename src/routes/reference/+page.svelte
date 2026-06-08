<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';

  let loading = true;
  let errorMsg = '';
  let saving = false;

  let suppliers = [];
  let categories = [];
  let ballCodes = [];
  let ballNames = [];

  let input = { supplier: '', category: '', ballCode: '', ballName: '' };

  async function loadAll() {
    loading = true;
    errorMsg = '';
    const [sup, cat, bc, bn] = await Promise.all([
      supabase.from('suppliers').select('id, code, name').order('code'),
      supabase.from('categories').select('id, name').order('name'),
      supabase.from('ball_codes').select('id, code').order('code'),
      supabase.from('ball_names').select('id, name').order('name')
    ]);
    const err = sup.error || cat.error || bc.error || bn.error;
    if (err) { errorMsg = err.message; loading = false; return; }
    suppliers = sup.data ?? [];
    categories = cat.data ?? [];
    ballCodes = bc.data ?? [];
    ballNames = bn.data ?? [];
    loading = false;
  }

  async function addSupplier() {
    const name = input.supplier.trim()
    if (!name) return
    saving = true
    const { error } = await supabase.from('suppliers').insert({ name })
    saving = false
    if (error) { errorMsg = error.message; return }
    input.supplier = ''
    await loadAll()
  }

  async function addCategory() {
    const name = input.category.trim();
    if (!name) return;
    saving = true;
    const { error } = await supabase.from('categories').upsert({ name }, { onConflict: 'name' });
    saving = false;
    if (error) { errorMsg = error.message; return; }
    input.category = '';
    await loadAll();
  }

  async function addBallCode() {
    const code = input.ballCode.trim();
    if (!code) return;
    saving = true;
    const { error } = await supabase.from('ball_codes').upsert({ code }, { onConflict: 'code' });
    saving = false;
    if (error) { errorMsg = error.message; return; }
    input.ballCode = '';
    await loadAll();
  }

  async function addBallName() {
    const name = input.ballName.trim();
    if (!name) return;
    saving = true;
    const { error } = await supabase.from('ball_names').upsert({ name }, { onConflict: 'name' });
    saving = false;
    if (error) { errorMsg = error.message; return; }
    input.ballName = '';
    await loadAll();
  }

async function removeRow(table, id, label) {
    if (!confirm('Hapus ' + label + '?')) return
    errorMsg = ''
    const { error } = await supabase.from(table).delete().eq('id', id)
    if (error) { errorMsg = error.message; return }
    await loadAll()
  }

  onMount(loadAll);
</script>

<h1 class="text-xl font-bold mb-1">Reference</h1>
<p class="text-sm text-gray-400 mb-5">Data master yang berulang. Nilai di sini muncul sebagai pilihan saat input di Purchasing.</p>

{#if errorMsg}
  <div class="mb-4 rounded border border-red-500/40 bg-red-500/10 px-3 py-2 text-sm text-red-300">{errorMsg}</div>
{/if}

<div class="grid gap-6 lg:grid-cols-2">
  <!-- Suppliers -->
  <section class="rounded-lg border border-[#2a2a2a] bg-[#111] overflow-hidden">
    <div class="px-4 py-3 border-b border-[#2a2a2a] flex items-center justify-between">
      <h2 class="font-semibold">Supplier</h2>
      <span class="text-xs text-gray-500">{suppliers.length}</span>
    </div>
    <div class="p-4 flex flex-wrap items-end gap-2">
      <label class="text-sm">Nama supplier
        <input bind:value={input.supplier} placeholder="Toko A" class="mt-1 w-48 rounded bg-[#0a0a0a] border border-[#2a2a2a] px-2 py-1.5" />
      </label>
      <button onclick={addSupplier} disabled={saving} class="rounded bg-green-500 text-black px-3 py-2 text-sm font-medium hover:bg-green-400 disabled:opacity-50">+ Tambah</button>
    </div>
    {#if !loading}
      <ul class="px-4 pb-4 flex flex-wrap gap-2">
        {#each suppliers as s}
          <li class="rounded border border-[#2a2a2a] bg-[#0a0a0a] px-2 py-1 text-xs flex items-center gap-1.5"><span>{s.name || s.code}</span><button type="button" onclick={() => removeRow('suppliers', s.id, s.name || s.code)} class="text-red-400 hover:text-red-300 leading-none" title="Hapus">×</button></li>
        {/each}
      </ul>
    {/if}
  </section>

  <!-- Categories -->
  <section class="rounded-lg border border-[#2a2a2a] bg-[#111] overflow-hidden">
    <div class="px-4 py-3 border-b border-[#2a2a2a] flex items-center justify-between">
      <h2 class="font-semibold">Kategori</h2>
      <span class="text-xs text-gray-500">{categories.length}</span>
    </div>
    <div class="p-4 flex items-end gap-2">
      <label class="text-sm">Nama kategori
        <input bind:value={input.category} placeholder="celana" class="mt-1 w-40 rounded bg-[#0a0a0a] border border-[#2a2a2a] px-2 py-1.5" />
      </label>
      <button onclick={addCategory} disabled={saving} class="rounded bg-green-500 text-black px-3 py-2 text-sm font-medium hover:bg-green-400 disabled:opacity-50">+ Tambah</button>
    </div>
    {#if !loading}
      <ul class="px-4 pb-4 flex flex-wrap gap-2">
        {#each categories as c}
          <li class="rounded border border-[#2a2a2a] bg-[#0a0a0a] px-2 py-1 text-xs flex items-center gap-1.5"><span>{c.name}</span><button type="button" onclick={() => removeRow('categories', c.id, c.name)} class="text-red-400 hover:text-red-300 leading-none" title="Hapus">×</button></li>
        {/each}
      </ul>
    {/if}
  </section>

  <!-- Ball Codes -->
  <section class="rounded-lg border border-[#2a2a2a] bg-[#111] overflow-hidden">
    <div class="px-4 py-3 border-b border-[#2a2a2a] flex items-center justify-between">
      <h2 class="font-semibold">Ball Code</h2>
      <span class="text-xs text-gray-500">{ballCodes.length}</span>
    </div>
    <div class="p-4 flex items-end gap-2">
      <label class="text-sm">Kode
        <input bind:value={input.ballCode} placeholder="AOSP" class="mt-1 w-40 rounded bg-[#0a0a0a] border border-[#2a2a2a] px-2 py-1.5" />
      </label>
      <button onclick={addBallCode} disabled={saving} class="rounded bg-green-500 text-black px-3 py-2 text-sm font-medium hover:bg-green-400 disabled:opacity-50">+ Tambah</button>
    </div>
    {#if !loading}
      <ul class="px-4 pb-4 flex flex-wrap gap-2">
        {#each ballCodes as b}
          <li class="rounded border border-[#2a2a2a] bg-[#0a0a0a] px-2 py-1 text-xs font-mono flex items-center gap-1.5"><span>{b.code}</span><button type="button" onclick={() => removeRow('ball_codes', b.id, b.code)} class="text-red-400 hover:text-red-300 leading-none" title="Hapus">×</button></li>
        {/each}
      </ul>
    {/if}
  </section>

  <!-- Ball Names -->
  <section class="rounded-lg border border-[#2a2a2a] bg-[#111] overflow-hidden">
    <div class="px-4 py-3 border-b border-[#2a2a2a] flex items-center justify-between">
      <h2 class="font-semibold">Nama Ball</h2>
      <span class="text-xs text-gray-500">{ballNames.length}</span>
    </div>
    <div class="p-4 flex items-end gap-2">
      <label class="text-sm">Nama
        <input bind:value={input.ballName} placeholder="Bola Plastik" class="mt-1 w-40 rounded bg-[#0a0a0a] border border-[#2a2a2a] px-2 py-1.5" />
      </label>
      <button onclick={addBallName} disabled={saving} class="rounded bg-green-500 text-black px-3 py-2 text-sm font-medium hover:bg-green-400 disabled:opacity-50">+ Tambah</button>
    </div>
    {#if !loading}
      <ul class="px-4 pb-4 flex flex-wrap gap-2">
        {#each ballNames as b}
          <li class="rounded border border-[#2a2a2a] bg-[#0a0a0a] px-2 py-1 text-xs flex items-center gap-1.5"><span>{b.name}</span><button type="button" onclick={() => removeRow('ball_names', b.id, b.name)} class="text-red-400 hover:text-red-300 leading-none" title="Hapus">×</button></li>
        {/each}
      </ul>
    {/if}
  </section>
</div>
