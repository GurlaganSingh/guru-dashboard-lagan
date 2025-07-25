<script lang="ts">
  import { Pie } from "svelte-chartjs";
  import { Chart as ChartJS, ArcElement, Tooltip, Legend } from "chart.js";
  ChartJS.register(ArcElement, Tooltip, Legend);

  type Item = { name: string; value: number };
  let { items }: { items: Item[] } = $props();

  const data = {
    labels: items.map(i => i.name),
    datasets: [
      {
        data: items.map(i => i.value),
        backgroundColor: ["#06b6d4", "#8b5cf6", "#ec4899", "#f59e0b"]
      }
    ]
  };
</script>

<div class="h-64 w-full">
  <Pie {data} options={{ responsive: true, maintainAspectRatio: false }} />
</div>
