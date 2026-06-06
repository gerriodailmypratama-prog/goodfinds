<script>
import '../app.css';
import { page } from '$app/stores';
const nav = [{ href: '/', label: 'Home' }, { href: '/purchasing', label: 'Purchasing' }];
let open = false;
</script>

<div class="min-h-screen bg-[#0a0a0a] text-[#f3f3f3]">
<header class="bg-[#0a0a0a] border-b border-[#2a2a2a] sticky top-0 z-20">
<div class="max-w-5xl mx-auto px-4 py-3 flex items-center gap-6">
<span class="font-bold text-lg">GoodFinds <span class="text-green-400">WMS</span></span>
<nav class="hidden sm:flex gap-4 text-sm">
{#each nav as item}
<a href={item.href} class="transition hover:text-green-400 {$page.url.pathname === item.href ? 'text-green-400 font-semibold' : 'text-gray-400'}">{item.label}</a>
{/each}
</nav>
<button class="sm:hidden ml-auto inline-flex items-center justify-center rounded p-2 text-gray-300 hover:bg-[#1a1a1a]" on:click={() => (open = !open)} aria-label="Menu">
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
</button>
</div>
{#if open}
<nav class="sm:hidden border-t border-[#2a2a2a] px-4 py-2 flex flex-col text-sm">
{#each nav as item}
<a href={item.href} on:click={() => (open = false)} class="py-2 transition hover:text-green-400 {$page.url.pathname === item.href ? 'text-green-400 font-semibold' : 'text-gray-300'}">{item.label}</a>
{/each}
</nav>
{/if}
</header>
<main class="max-w-5xl mx-auto px-4 py-6">
<slot />
</main>
</div>
