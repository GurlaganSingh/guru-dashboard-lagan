import type { PageServerLoad } from "./$types";

export const load: PageServerLoad = async () => {
  const res = await fetch("http://localhost:4000/items");
  const items = await res.json();
  return { items };
};
