<script lang="ts">
  import { goto } from "$app/navigation";

  let email = $state("");
  let password = $state("");
  let loading = $state(false);

  async function login() {
    loading = true;
    // fake latency
    await new Promise(r => setTimeout(r, 600));
    loading = false;
    goto("/dashboard");            // <- redirect!
  }
</script>

<svelte:head><title>Login</title></svelte:head>

<div class="flex min-h-screen items-center justify-center">
  <form onsubmit={login} class="glass w-full max-w-sm p-8 space-y-4">
    <h1 class="text-2xl font-bold text-center">Admin Login</h1>
    <input bind:value={email} type="email" placeholder="Email" required class="w-full rounded p-2 bg-transparent ring-1 ring-neutral-700 focus:ring-cyan-400 outline-none" />
    <input bind:value={password} type="password" placeholder="Password" required class="w-full rounded p-2 bg-transparent ring-1 ring-neutral-700 focus:ring-cyan-400 outline-none" />
    <button disabled={loading} class="w-full rounded bg-cyan-500 px-4 py-2 font-semibold text-black">
      {loading ? "Logging in…" : "Login"}
    </button>
  </form>
</div>
