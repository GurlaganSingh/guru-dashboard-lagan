#!/usr/bin/env bash
set -e
echo "🛠️  Patching skeleton → dashboard…"

# 1. Upgrade deps
bun add -D @tailwindcss/typography@next @tailwindcss/vite tailwindcss-motion
bun add @supabase/supabase-js lucide-svelte chart.js svelte-chartjs

# 2. Tailwind v4 CSS (glass + dark)
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

# 3. Vite config
cat > vite.config.ts <<'EOF'
import { sveltekit } from "@sveltejs/kit/vite";
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()]
});
EOF

# 4. Supabase client
mkdir -p src/lib
cat > src/lib/supabase.ts <<'EOF'
import { createClient } from "@supabase/supabase-js";
const url = import.meta.env.VITE_SUPABASE_URL ?? "";
const key = import.meta.env.VITE_SUPABASE_ANON_KEY ?? "";
export const supabase = createClient(url, key);
EOF

# 5. Root layout
cat > src/routes/+layout.svelte <<'EOF'
<script lang="ts">
  import "../app.css";
  let { children } = $props();
</script>
<main class="min-h-screen bg-bg text-fg">{@render children()}</main>
EOF

# 6. Home → redirect to login
cat > src/routes/+page.svelte <<'EOF'
<script lang="ts">
  import { goto } from "$app/navigation";
  goto("/login");
</script>
EOF

# 7. Login page
mkdir -p src/routes/login
cat > src/routes/login/+page.svelte <<'EOF'
<script lang="ts">
  import { goto } from "$app/navigation";
  import { supabase } from "$lib/supabase";

  let email = $state("");
  let password = $state("");
  let loading = $state(false);

  async function login() {
    loading = true;
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    loading = false;
    if (!error) goto("/dashboard");
  }
</script>

<div class="flex min-h-screen items-center justify-center">
  <form onsubmit={login} class="glass w-full max-w-sm p-8 space-y-4">
    <h1 class="text-2xl font-bold">Admin Login</h1>
    <input bind:value={email} type="email" placeholder="Email" required class="w-full rounded p-2 bg-transparent ring-1 ring-neutral-700 focus:ring-cyan-400 outline-none" />
    <input bind:value={password} type="password" placeholder="Password" required class="w-full rounded p-2 bg-transparent ring-1 ring-neutral-700 focus:ring-cyan-400 outline-none" />
    <button disabled={loading} class="w-full rounded bg-cyan-500 px-4 py-2 font-semibold text-black">Login</button>
  </form>
</div>
EOF

# 8. Dashboard page
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
  import type { PageData } from "./$types";
  type Item = { id: number; name: string; value: number };
  let { data }: { data: PageData } = $props();
</script>

<svelte:head><title>Dashboard</title></svelte:head>

<nav class="flex items-center justify-between p-4 glass sticky top-0 z-10">
  <h1 class="text-xl font-bold">Admin Dashboard</h1>
  <form action="/logout" method="POST">
    <button class="text-sm underline">Logout</button>
  </form>
</nav>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 p-6">
  <!-- CRUD Table -->
  <section class="lg:col-span-2 glass rounded-xl p-4">
    <h2 class="mb-4 text-lg font-semibold">Items CRUD</h2>
    <table class="w-full text-sm">
      <thead>
        <tr class="border-b border-neutral-700">
          <th>Name</th><th>Value</th>
        </tr>
      </thead>
      <tbody>
        {#each data.items as item}
          <tr class="border-b border-neutral-800">
            <td>{item.name}</td><td>{item.value}</td>
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
EOF

# 9. Logout handler
cat > src/routes/logout/+server.ts <<'EOF'
import { redirect } from "@sveltejs/kit";
import { supabase } from "$lib/supabase";

export async function POST() {
  await supabase.auth.signOut();
  throw redirect(303, "/login");
}
EOF

# 10. App.html dark favicon
cat > src/app.html <<'EOF'
<!doctype html>
<html lang="en" class="scroll-smooth">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>📊</text></svg>" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    %sveltekit.head%
  </head>
  <body data-sveltekit-preload-data="hover">
    <div style="display: contents">%sveltekit.body%</div>
  </body>
</html>
EOF

echo "✅ Patched. Start with:"
echo "  bun run dev --host --open"
