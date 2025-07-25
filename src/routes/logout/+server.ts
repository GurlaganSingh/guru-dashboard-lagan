import { redirect } from "@sveltejs/kit";
import { supabase } from "$lib/supabase";

export async function POST() {
  await supabase.auth.signOut();
  throw redirect(303, "/login");
}
