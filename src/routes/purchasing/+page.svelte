<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase';
  import { rupiah, angka, persen } from '$lib/format';

  let suppliers = [];
  let balls = [];
  let loading = true;
  let saving = false;
  let errorMsg = '';

  // form state
  let form = {
    ball_code: '',
    category: '',
    supplier_id: '',
    buy_price: '',
    qty_pcs: '',
    qty_reject: 0
  };

  // new supplier
  let newSupplierCode = '';

  async function loadAll() {
    loading = true;
    errorMsg = '';
    const [sRes, bRes] = await Promise.all([
      supabase.from('suppliers').select('id, code, name').order('code'),
      supabase.from('v_ball_economics').select('*').order('buy_date', { ascending: false })
    ]);
    if (sRes.error) errorMsg = sRes.error.message;
    if (bRes.error) errorMsg = bRes.error.message;
    suppliers = sRes.data ?? [];
    balls = bRes.data ?? [];
    loading = false;
  }

  async function addSupplier() {
    if (!newSupplierCode.trim()) return;
    const { error } = await supabase.from('suppliers').insert({ code: newSupplierCode.trim() });
    if (error) { errorMsg = error.message; return; }
    newSupplierCode = '';
    await loadAll();
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
      category: form.category.trim(),
      supplier_id: form.supplier_id || null,
      buy_price: Number(form.buy_price),
      qty_pcs: form.qty_pcs === '' ? null : Number(form.qty_pcs),
      qty_reject: form.qty_reject === '' ? 0 : Number(form.qty_reject),
      status: 'bought'
    };
    const { error } = await supabase.from('balls').insert(payload);
    saving = false;
    if (error) { errorMsg = error.message; return; }
    form = { ball_code: '', category: '', supplier_id: '', buy_price: '', qty_pcs: '', qty_reject: 0 };
    await loadAll();
  }

  onMount(loadAll);
</script>

<div class="space-y-6">
  <h1 class="text-2xl font-bold">Purchasing</h1>

  {#if errorMsg}
    <div class="rounded border border-red-300 bg-red-50 text-red-700 px-3 py-2 text-sm">{errorMsg}</div>
  {/if}

  <!-- Form input ball -->
  <section class="rounded-lg border border-gray-200 bg-white p-5 space-y-4">
    <h2 class="font-semibold">Input Ball Baru</h2>
    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <label class="text-sm">Ball Code
        <input bind:value={form.ball_code} placeholder="AOSP" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
      </label>
      <label class="text-sm">Kategori
        <input bind:value={form.category} placeholder="celana" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
      </label>
      <label class="text-sm">Supplier
        <select bind:value={form.supplier_id} class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5">
          <option value="">- pilih -</option>
          {#each suppliers as s}
            <option value={s.id}>{s.code}{s.name ? ' (' + s.name + ')' : ''}</option>
          {/each}
        </select>
      </label>
      <label class="text-sm">Harga Beli (Rp)
        <input type="number" bind:value={form.buy_price} placeholder="8500000" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
      </label>
      <label class="text-sm">Qty Pcs (layak)
        <input type="number" bind:value={form.qty_pcs} placeholder="475" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
      </label>
      <label class="text-sm">Qty Reject (dibuang)
        <input type="number" bind:value={form.qty_reject} placeholder="0" class="mt-1 w-full rounded border-gray-300 border px-2 py-1.5" />
      </label>
    </div>
    <button on:click={saveBall} disabled={saving} class="rounded bg-emerald-600 text-white px-4 py-2 text-sm font-medium hover:bg-emerald-700 disabled:opacity-50">
      {saving ? 'Menyimpan...' : 'Simpan Ball'}
    </button>
  </section>

  <!-- Tambah supplier -->
  <section class="rounded-lg border border-gray-200 bg-white p-4 flex items-end gap-3">
    <label class="text-sm">Tambah Supplier (kode)
      <input bind:value={newSupplierCode} placeholder="A" class="mt-1 w-32 rounded border-gray-300 border px-2 py-1.5" />
    </label>
    <button on:click={addSupplier} class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50">+ Supplier</button>
  </section>

  <!-- Tabel ball -->
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
              <th class="px-4 py-2">Ball</th>
              <th class="px-4 py-2">Kategori</th>
              <th class="px-4 py-2">Seller</th>
              <th class="px-4 py-2 text-right">Harga Beli</th>
              <th class="px-4 py-2 text-right">Pcs</th>
              <th class="px-4 py-2 text-right">Reject</th>
              <th class="px-4 py-2 text-right">Modal/Pcs</th>
              <th class="px-4 py-2 text-right">Reject %</th>
            </tr>
          </thead>
          <tbody>
            {#each balls as b}
              <tr class="border-t border-gray-100">
                <td class="px-4 py-2 font-medium">{b.ball_code}</td>
                <td class="px-4 py-2">{b.category}</td>
                <td class="px-4 py-2">{b.supplier_code ?? '-'}</td>
                <td class="px-4 py-2 text-right">{rupiah(b.buy_price)}</td>
                <td class="px-4 py-2 text-right">{angka(b.qty_pcs)}</td>
                <td class="px-4 py-2 text-right">{angka(b.qty_reject)}</td>
                <td class="px-4 py-2 text-right font-semibold">{rupiah(b.modal_per_pcs)}</td>
                <td class="px-4 py-2 text-right">{persen(b.reject_pct)}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}
  </section>
</div>
