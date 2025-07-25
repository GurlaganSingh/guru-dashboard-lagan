<script lang="ts">
  import { supabase } from "$lib/supabase";
  import { invalidateAll } from "$app/navigation";

  type Item = { id: number; name: string; value: number };
  let { items }: { items: Item[] } = $props();

  let search = $state("");
  let sort = $state<keyof Item>("name");
  let asc = $state(true);

  $: filtered = items
    .filter(i => i.name.toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => {
      const dir = asc ? 1 : -1;
      return a[sort] > b[sort] ? dir : -dir;
    });

  async function del(id: number) {
    await supabase.from("items").delete().eq("id", id);
    invalidateAll();
  }
</script>

<input
  bind:value={search}
  placeholder="Search…"
  class="mb-2 w-full rounded bg-transparent p-2 ring-1 ring-neutral-700 focus:ring-cyan-400 outline-none"
/>

<table class="w-full text-sm">
  <thead>
    <tr class="border-b border-neutral-700">
      <th class="cursor-pointer" onclick={() => (sort = "name")}>Name</th>
      <th class="cursor-pointer" onclick={() => (sort = "value")}>Value</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    {#each filtered as item}
      <tr class="border-b border-neutral-800">
        <td>{item.name}</td>
        <td>{item.value}</td>
        <td>
          <button onclick={() => del(item.id)} class="text-red-400">Delete</button>
        </td>
      </tr>
    {/each}
  </tbody>
</table>
