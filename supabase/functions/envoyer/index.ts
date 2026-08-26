// Envoi de messages aux clients, par Brevo.
//
// Pourquoi une fonction sur le serveur, et pas un appel direct depuis la page :
// la clé Brevo donne le droit d'envoyer des courriels et des SMS depuis le
// compte de la boutique, aux frais de la boutique. Une page web est lisible
// par n'importe qui — glisser la clé dedans reviendrait à la publier. Elle
// reste donc ici, dans les secrets Supabase, et la page ne fait que demander.
//
// Ce que cette fonction vérifie avant d'envoyer quoi que ce soit :
//   1. l'appelant est authentifié et inscrit dans la table « staff » ;
//   2. les destinataires sont relus dans la base — le navigateur n'envoie que
//      des numéros de carte, jamais des adresses ni des téléphones ;
//   3. pour une offre commerciale, seuls les clients ayant accepté de recevoir
//      les offres sont retenus. Ce filtre existe déjà dans la page ; il est
//      refait ici parce qu'un filtre côté navigateur ne protège personne.
//
// Secrets attendus (Supabase → Edge Functions → Secrets) :
//   BREVO_KEY          la clé d'API v3 du compte Brevo
//
// Le reste — expéditeur, nom, nom court pour les SMS, adresse du site — est
// rangé dans la fiche boutique, en base : ce ne sont pas des secrets.

import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MAX_DESTINATAIRES = 300;   // garde-fou : une fausse manœuvre ne doit pas vider le compte
const MAX_SMS = 100;             // les SMS sont facturés à l'unité
const LOT_COURRIEL = 50;         // Brevo accepte jusqu'à 1000 versions par appel
const MAX_TEXTE = 1000;
const MAX_SUJET = 200;

type Fiche = {
  id: string; name: string; email: string | null; phone: string;
  marketing: boolean; token: string;
};

function reponse(corps: unknown, code = 200) {
  return new Response(JSON.stringify(corps), {
    status: code,
    headers: { ...CORS, "content-type": "application/json" },
  });
}

function echappe(s: string) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
          .replace(/"/g, "&quot;");
}

/* Le téléphone tel que Brevo l'attend : indicatif pays, sans « + » ni espaces.
   Les fiches sont saisies au format français, on complète donc le 33. */
function international(tel: string): string | null {
  const n = String(tel || "").replace(/[^0-9+]/g, "");
  if (/^\+?33[1-9]\d{8}$/.test(n)) return n.replace(/^\+/, "");
  if (/^0[1-9]\d{8}$/.test(n)) return "33" + n.slice(1);
  if (/^\+?[1-9]\d{9,14}$/.test(n)) return n.replace(/^\+/, "");
  return null;
}

async function brevo(chemin: string, cle: string, corps: unknown) {
  const r = await fetch("https://api.brevo.com/v3" + chemin, {
    method: "POST",
    headers: { "api-key": cle, "content-type": "application/json", accept: "application/json" },
    body: JSON.stringify(corps),
  });
  const t = await r.text();
  let d: Record<string, unknown> = {};
  try { d = t ? JSON.parse(t) : {}; } catch { d = { message: t }; }
  if (!r.ok) {
    throw new Error(String(d.message || d.code || ("Brevo a répondu " + r.status)));
  }
  return d;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return reponse({ erreur: "methode" }, 405);

  const cle = Deno.env.get("BREVO_KEY");
  if (!cle) return reponse({ erreur: "brevo_non_configure" }, 400);

  const auth = req.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) return reponse({ erreur: "non_authentifie" }, 401);

  // Le client parle avec le jeton de l'appelant : les politiques RLS
  // s'appliquent telles quelles, la fonction n'a aucun privilège en plus.
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );

  const { data: staff, error: eStaff } = await db.rpc("is_staff");
  if (eStaff || staff !== true) return reponse({ erreur: "reserve_au_personnel" }, 403);

  let corps: Record<string, unknown>;
  try { corps = await req.json(); } catch { return reponse({ erreur: "corps_illisible" }, 400); }

  const canal = corps.canal === "sms" ? "sms" : "email";
  const nature = corps.nature === "commercial" ? "commercial" : "service";
  const ids = Array.isArray(corps.ids) ? corps.ids.map(String).slice(0, MAX_DESTINATAIRES) : [];
  const texte = String(corps.texte || "").slice(0, MAX_TEXTE).trim();
  const sujet = String(corps.sujet || "").slice(0, MAX_SUJET).trim();

  if (!ids.length) return reponse({ erreur: "aucun_destinataire" }, 400);
  if (!texte) return reponse({ erreur: "texte_vide" }, 400);
  if (canal === "email" && !sujet) return reponse({ erreur: "sujet_vide" }, 400);

  // ── la boutique, et sa configuration d'envoi ──
  const { data: boutique, error: eShop } = await db.from("shop").select("data").eq("id", 1).single();
  if (eShop || !boutique) return reponse({ erreur: "boutique_introuvable" }, 500);
  const conf = (boutique.data?.envoi || {}) as Record<string, string>;
  const nomBoutique = String(boutique.data?.name || "La boutique");

  if (canal === "email" && !conf.from_email) return reponse({ erreur: "expediteur_manquant" }, 400);
  if (canal === "sms" && !conf.sms_sender) return reponse({ erreur: "nom_court_manquant" }, 400);

  // ── les destinataires, relus en base ──
  const { data: fiches, error: eCli } = await db
    .from("clients")
    .select("id, name, email, phone, marketing, token")
    .in("id", ids);
  if (eCli) return reponse({ erreur: "lecture_impossible", detail: eCli.message }, 500);

  const tous = (fiches || []) as Fiche[];
  const ecartes = nature === "commercial" ? tous.filter((c) => !c.marketing) : [];
  const consentants = nature === "commercial" ? tous.filter((c) => c.marketing) : tous;

  // Consentant mais sans adresse ni téléphone : ni écarté, ni envoyé. Le
  // compte doit tomber juste, sinon le boucher cherche des messages fantômes.
  const retenus = canal === "email"
    ? consentants.filter((c) => (c.email || "").includes("@"))
    : consentants.filter((c) => international(c.phone));
  const injoignables = consentants.length - retenus.length;

  if (!retenus.length) {
    return reponse({ envoyes: 0, ecartes: ecartes.length, injoignables, echecs: [], raison: "aucun_joignable" });
  }
  if (canal === "sms" && retenus.length > MAX_SMS) {
    return reponse({ erreur: "trop_de_sms", limite: MAX_SMS, demandes: retenus.length }, 400);
  }

  const site = String(conf.site_url || "").replace(/\/+$/, "");
  const echecs: { id: string; raison: string }[] = [];
  let envoyes = 0;
  let credits: number | null = null;

  if (canal === "email") {
    const expediteur = { name: conf.from_name || nomBoutique, email: conf.from_email };
    for (let i = 0; i < retenus.length; i += LOT_COURRIEL) {
      const lot = retenus.slice(i, i + LOT_COURRIEL);
      const versions = lot.map((c) => {
        // Une offre commerciale doit porter le moyen de s'y soustraire.
        const lien = site ? site + "?c=" + c.token : "";
        const pied = nature === "commercial" && lien
          ? "\n\n—\nPour ne plus recevoir nos offres, ouvrez votre carte et décochez la case : " + lien
          : "";
        const brut = texte + pied;
        return {
          to: [{ email: c.email as string, name: c.name }],
          subject: sujet,
          textContent: brut,
          htmlContent: "<div style=\"font:15px/1.6 -apple-system,Segoe UI,Arial,sans-serif;color:#171718\">" +
            echappe(brut).replace(/\n/g, "<br>") + "</div>",
        };
      });
      try {
        await brevo("/smtp/email", cle, {
          sender: expediteur,
          to: [{ email: lot[0].email as string, name: lot[0].name }],
          subject: sujet,
          textContent: texte,
          messageVersions: versions,
        });
        envoyes += lot.length;
      } catch (e) {
        const raison = e instanceof Error ? e.message : String(e);
        lot.forEach((c) => echecs.push({ id: c.id, raison }));
      }
    }
  } else {
    // Pas d'envoi groupé pour les SMS chez Brevo : un appel par destinataire,
    // cinq de front pour ne pas dépasser le temps imparti à la fonction.
    const file = retenus.slice();
    const ouvrier = async () => {
      for (;;) {
        const c = file.shift();
        if (!c) return;
        try {
          const d = await brevo("/transactionalSMS/sms", cle, {
            sender: conf.sms_sender,
            recipient: international(c.phone),
            content: texte,
            type: nature === "commercial" ? "marketing" : "transactional",
          });
          envoyes++;
          if (typeof d.remainingCredits === "number") credits = d.remainingCredits as number;
        } catch (e) {
          echecs.push({ id: c.id, raison: e instanceof Error ? e.message : String(e) });
        }
      }
    };
    await Promise.all([ouvrier(), ouvrier(), ouvrier(), ouvrier(), ouvrier()]);
  }

  // ── le journal : ce qui est parti, jamais à qui ni quoi ──
  await db.from("log").insert({
    m: "Envoi " + (nature === "commercial" ? "commercial" : "de service") +
      " par " + (canal === "sms" ? "SMS" : "courriel") + " (Brevo) : " +
      envoyes + " parti(s)" +
      (ecartes.length ? ", " + ecartes.length + " écarté(s) faute d'accord" : "") +
      (echecs.length ? ", " + echecs.length + " en échec" : ""),
  });

  return reponse({ envoyes, ecartes: ecartes.length, injoignables, echecs, credits });
});
