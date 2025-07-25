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
