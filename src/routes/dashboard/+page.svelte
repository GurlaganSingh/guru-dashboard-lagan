<script lang="ts">
  import { onMount } from "svelte";

  type Item = { id: number; name: string; value: number };
  let items = $state<Item[]>([]);

  onMount(async () => {
    const res = await fetch("http://localhost:4000/items");
    items = await res.json();
  });
</script>

<svelte:head><title>Dashboard</title></svelte:head>

<nav class="flex items-center justify-between p-4 glass sticky top-0 z-10">
  <h1 class="text-xl font-bold">Admin Dashboard</h1>
  <a href="/" class="text-sm underline">Home</a>
</nav>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 p-6">
  <!-- Data table -->
  <section class="lg:col-span-2 glass rounded-xl p-4">
    <h2 class="mb-4 text-lg font-semibold">Items CRUD</h2>
    <table class="w-full text-sm">
      <thead>
        <tr class="border-b border-neutral-700">
          <th class="text-left p-2">Name</th>
          <th class="text-left p-2">Value</th>
        </tr>
      </thead>
      <tbody>
        {#each items as item}
          <tr class="border-b border-neutral-800">
            <td class="p-2">{item.name}</td>
            <td class="p-2">{item.value}</td>
          </tr>
        {/each}
      </tbody>
    </table>
  </section>

  <!-- Chart placeholder -->
  <section class="glass rounded-xl p-4">
    <h2 class="mb-4 text-lg font-semibold">Data Visual</h2>
    <div class="h-64 flex items-center justify-center text-neutral-500">
      Chart coming soon
    </div>
  </section>
</div>
