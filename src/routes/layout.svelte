<script>
  import '../app.css';
  import { page } from '$app/stores';

  const nav = [
    { href: '/', label: 'Home' },
    { href: '/purchasing', label: 'Purchasing' }
  ];
</script>

<div class="min-h-screen bg-gray-50 text-gray-900">
  <header class="bg-white border-b border-gray-200">
    <div class="max-w-5xl mx-auto px-4 py-3 flex items-center gap-6">
      <span class="font-bold text-lg">GoodFinds <span class="text-emerald-600">WMS</span></span>
      <nav class="flex gap-4 text-sm">
        {#each nav as item}
          <a
            href={item.href}
            class="hover:text-emerald-600 {$page.url.pathname === item.href ? 'text-emerald-600 font-semibold' : 'text-gray-600'}"
          >{item.label}</a>
        {/each}
      </nav>
    </div>
  </header>
  <main class="max-w-5xl mx-auto px-4 py-6">
    <slot />
  </main>
</div>
