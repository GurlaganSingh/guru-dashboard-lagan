#!/usr/bin/env bash
# make-dashboard.sh – scaffold SvelteKit + Tailwind 4 dashboard
set -e
PROJECT_DIR="../prt"
echo "🧾 Creating $PROJECT_DIR …"

# 1. Fresh SvelteKit skeleton with TypeScript
bun x sv create "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 2. Install deps
bun install
bun add -D @tailwindcss/typography @tailwindcss/vite tailwindcss-motion
bun add @supabase/supabase-js lucide-svelte chart.js svelte-chartjs

# 3. Tailwind CSS v4
cat > src/app.css <<'EOF'
@import "tailwindcss";
@plugin "@tailwindcss/typography";

:root {
  --bg: #0a0a0a;
  --bg-panel: #111111;
  --fg: #f5f5f5;
  --accent: #06b6d4;
}

body {
  background: var(--bg);
  color: var(--fg);
  font-family: "Inter", system-ui, sans-serif;
}

.glass {
  backdrop-filter: blur(16px) saturate(180%);
  -webkit-backdrop-filter: blur(16px) saturate(180%);
  background: rgba(255 255 255 / 0.05);
  border: 1px solid rgba(255 255 255 / 0.08);
}
EOF

# 4. Vite config with Tailwind plugin
cat > vite.config.ts <<'EOF'
import { sveltekit } from "@sveltejs/kit/vite";
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()]
});
EOF

# 5. Supabase client
mkdir -p src/lib
cat > src/lib/supabase.ts <<'EOF'
import { createClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL ?? "";
const key = import.meta.env.VITE_SUPABASE_ANON_KEY ?? "";
export const supabase = createClient(url, key);
EOF

# 6. Auth guard
cat > src/lib/auth.ts <<'EOF'
import { redirect } from "@sveltejs/kit";
import type { PageLoad } from "./$types";

export const load: PageLoad = async ({ parent }) => {
  const { session } = await parent();
  if (!session) throw redirect(303, "/login");
};
EOF

# 7. Hooks (server-side session)
mkdir -p src/hooks
cat > src/hooks/server.ts <<'EOF'
import type { Handle } from "@sveltejs/kit";
import { supabase } from "$lib/supabase";

export const handle: Handle = async ({ event, resolve }) => {
  const token = event.cookies.get("sb-token");
  if (token) {
    const { data, error } = await supabase.auth.getUser(token);
    event.locals.session = error ? null : data.user;
  }
  return resolve(event);
};
EOF

# 8. Layouts
cat > src/routes/+layout.server.ts <<'EOF'
import type { LayoutServerLoad } from "./$types";

export const load: LayoutServerLoad = async ({ locals }) => ({
  session: locals.session
});
EOF

cat > src/routes/+layout.svelte <<'EOF'
<script lang="ts">
  import "../app.css";
  let { children } = $props();
</script>

<main class="min-h-screen bg-bg text-fg">{@render children()}</main>
EOF

# 9. Login page
mkdir -p src/routes/login
cat > src/routes/login/+page.svelte <<'EOF'
<script lang="ts">
  import { goto } from "$app/navigation";
  import { supabase } from "$lib/supabase";

  let email = $state("");
  let password = $state("");
  let loading = $state(false);

  async function handleSubmit() {
    loading = true;
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    loading = false;
    if (!error) goto("/dashboard");
  }
</script>

<svelte:head><title>Login</title></svelte:head>

<div class="flex min-h-screen items-center justify-center">
  <form onsubmit={handleSubmit} class="glass w-full max-sm mx-4 rounded-xl p-8 space-y-4">
    <h1 class="text-2xl font-bold">Login</h1>
    <input bind:value={email} type="email" placeholder="Email" required class="w-full rounded bg-transparent p-2 ring-1 ring-neutral-700 focus:ring-accent outline-none" />
    <input bind:value={password} type="password" placeholder="Password" required class="w-full rounded bg-transparent p-2 ring-1 ring-neutral-700 focus:ring-accent outline-none" />
    <button disabled={loading} class="w-full rounded bg-accent px-4 py-2 font-semibold text-black">Login</button>
  </form>
</div>
EOF

# 10. Dashboard shell
mkdir -p src/routes/dashboard
cat > src/routes/dashboard/+page.server.ts <<'EOF'
import { redirect } from "@sveltejs/kit";
import type { PageServerLoad } from "./$types";
import { supabase } from "$lib/supabase";

export const load: PageServerLoad = async ({ parent }) => {
  const { session } = await parent();
  if (!session) throw redirect(303, "/login");

  const { data } = await supabase.from("items").select("*");
  return { items: data ?? [] };
};
EOF

cat > src/routes/dashboard/+page.svelte <<'EOF'
<script lang="ts">
  import { enhance } from "$app/forms";
  import type { PageData } from "./$types";
  import DataTable from "$lib/components/DataTable.svelte";
  import Chart from "$lib/components/Chart.svelte";

  let { data }: { data: PageData } = $props();
</script>

<svelte:head><title>Dashboard</title></svelte:head>

<nav class="flex items-center justify-between p-4 glass sticky top-0 z-10">
  <h1 class="text-xl font-bold">Admin Dashboard</h1>
  <form action="/logout" method="POST" use:enhance>
    <button class="text-sm underline">Logout</button>
  </form>
</nav>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 p-6">
  <section class="lg:col-span-2 glass rounded-xl p-4">
    <h2 class="mb-4 text-lg font-semibold">Items CRUD</h2>
    <DataTable items={data.items} />
  </section>

  <section class="glass rounded-xl p-4">
    <h2 class="mb-4 text-lg font-semibold">Data Visual</h2>
    <Chart items={data.items} />
  </section>
</div>
EOF

# 11. Logout action
cat > src/routes/logout/+server.ts <<'EOF'
import { redirect } from "@sveltejs/kit";
import { supabase } from "$lib/supabase";

export async function POST() {
  await supabase.auth.signOut();
  throw redirect(303, "/login");
}
EOF

# 12. Reusable components
mkdir -p src/lib/components
cat > src/lib/components/DataTable.svelte <<'EOF'
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

<input bind:value={search} placeholder="Search…" class="mb-2 w-full rounded bg-transparent p-2 ring-1 ring-neutral-700" />

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
EOF

cat > src/lib/components/Chart.svelte <<'EOF'
<script lang="ts">
  import { Pie } from "svelte-chartjs";
  import { Chart as ChartJS, ArcElement, Tooltip, Legend } from "chart.js";

  ChartJS.register(ArcElement, Tooltip, Legend);

  let { items } = $props();
  const data = {
    labels: items.map((i: any) => i.name),
    datasets: [{ data: items.map((i: any) => i.value), backgroundColor: ["#06b6d4", "#8b5cf6", "#ec4899"] }]
  };
</script>

<div class="h-64 w-full"><Pie {data} /></div>
EOF

# 13. Seed SQL (optional)
cat > seed.sql <<'EOF'
create table if not exists items (
  id serial primary key,
  name text not null,
  value int
);
insert into items (name, value) values ('Alpha', 42), ('Beta', 27), ('Gamma', 15);
EOF

echo "✅ Dashboard scaffold complete!"
echo "Steps:"
echo "  1.  cd $PROJECT_DIR"
echo "  2.  Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in .env"
echo "  3.  Run 'bun run dev --open'"
echo "  4.  Execute seed.sql in Supabase SQL editor to create items table."
