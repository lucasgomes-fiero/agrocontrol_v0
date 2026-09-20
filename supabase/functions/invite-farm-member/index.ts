
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return reply({ error: "Não autenticado." }, 401);

    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(url, anon, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const admin = createClient(url, service, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: current, error: userError } = await userClient.auth.getUser();
    if (userError || !current.user) return reply({ error: "Sessão inválida." }, 401);

    const body = await req.json();
    const farmId = String(body.farm_id ?? "");
    const email = String(body.email ?? "").trim().toLowerCase();
    const role = String(body.role ?? "member");
    const mode = String(body.mode ?? "invite");
    const fullName = String(body.full_name ?? "").trim();
    const password = String(body.password ?? "");

    if (!farmId || !email || !["admin", "member", "viewer"].includes(role)) {
      return reply({ error: "Dados de acesso inválidos." }, 400);
    }
    if (!email.includes("@")) return reply({ error: "Informe um e-mail válido." }, 400);
    if (mode === "create" && password.length < 8) {
      return reply({ error: "A senha inicial precisa ter pelo menos 8 caracteres." }, 400);
    }

    const { data: membership, error: membershipError } = await admin
      .from("farm_members")
      .select("role")
      .eq("farm_id", farmId)
      .eq("user_id", current.user.id)
      .maybeSingle();

    if (membershipError) throw membershipError;
    if (!membership || !["owner", "admin"].includes(membership.role)) {
      return reply({ error: "Apenas proprietários e administradores podem criar acessos." }, 403);
    }

    let target: any = null;
    for (let page = 1; page <= 10 && !target; page++) {
      const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
      if (error) throw error;
      target = data.users.find((u) => u.email?.toLowerCase() === email);
      if (data.users.length < 1000) break;
    }

    let created = false;
    if (!target) {
      if (mode === "create") {
        const { data, error } = await admin.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: { full_name: fullName },
        });
        if (error) return reply({ error: error.message }, 400);
        target = data.user;
        created = true;
      } else {
        const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
          data: { full_name: fullName },
        });
        if (error) return reply({ error: error.message }, 400);
        target = data.user;
        created = true;
      }
    }

    if (!target) return reply({ error: "Não foi possível criar ou localizar o usuário." }, 500);

    if (fullName && !created) {
      const { error: profileError } = await admin.from("profiles")
        .update({ full_name: fullName })
        .eq("id", target.id);
      if (profileError) throw profileError;
    }

    const { error: upsertError } = await admin.from("farm_members").upsert(
      { farm_id: farmId, user_id: target.id, role },
      { onConflict: "farm_id,user_id" },
    );
    if (upsertError) throw upsertError;

    return reply({ ok: true, user_id: target.id, email, role, mode, created });
  } catch (error) {
    return reply({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});

function reply(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, "Content-Type": "application/json; charset=utf-8" },
  });
}
