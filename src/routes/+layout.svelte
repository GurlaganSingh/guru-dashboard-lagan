<script lang="ts">
  import "../app.css";
  let { children } = $props();
</script>
<main class="min-h-screen bg-bg text-fg">{@render children()}</main>
