// Prépare le dossier publié : uniquement la page de l'application.
// Le reste du dépôt (schéma, scripts, démo, documentation) n'a rien à faire
// sur l'hébergement public.
import fs from "node:fs";
import { execSync } from "node:child_process";
fs.rmSync("public", { recursive: true, force: true });
fs.mkdirSync("public", { recursive: true });
// L'estampille : la date de publication et le commit exact. C'est ce qui
// permet de répondre à « est-ce que c'est en ligne ? » en regardant l'écran
// plutôt qu'en rechargeant à l'aveugle.
const commit = (process.env.VERCEL_GIT_COMMIT_SHA || "").slice(0, 7) ||
  (() => { try { return execSync("git rev-parse --short HEAD").toString().trim(); }
           catch { return "inconnu"; } })();
const quand = new Date().toLocaleDateString("fr-FR",
  { day: "numeric", month: "long", hour: "2-digit", minute: "2-digit", timeZone: "Europe/Paris" });
const page = fs.readFileSync("index.html", "utf8")
  .replace('var VERSION = "atelier";', 'var VERSION = ' + JSON.stringify(quand + " · " + commit) + ";");
if (page.indexOf('var VERSION = "atelier"') >= 0) {
  console.error("\n  ⚠  Estampille non posée : le marqueur VERSION a changé de forme.\n");
}
fs.writeFileSync("public/index.html", page);
// Les polices voyagent avec le site : rien n'est demandé à un serveur tiers,
// et le texte est déjà à sa place au premier affichage.
fs.mkdirSync("public/police", { recursive: true });
for (const f of fs.readdirSync("assets/police")) {
  if (f.endsWith(".woff2")) fs.copyFileSync("assets/police/" + f, "public/police/" + f);
}
const cfg = JSON.parse(
  fs.readFileSync("index.html", "utf8").match(/<script id="sbcfg"[^>]*>(.*?)<\/script>/)[1]
);
if (!cfg.url || !cfg.key) {
  console.error("\n  ⚠  Aucune base configurée dans le bloc sbcfg de index.html.");
  console.error("     Le site publié fonctionnera en mode local, sans base partagée.\n");
}
// Le décodeur de QR voyage à part : seul l'espace boucher le télécharge,
// et seulement au moment où il ouvre le scanner.
fs.copyFileSync("vendor/jsqr.min.js", "public/scanner.js");

console.log("public/index.html —", (fs.statSync("public/index.html").size / 1024).toFixed(1), "Ko");
console.log("public/scanner.js —", (fs.statSync("public/scanner.js").size / 1024).toFixed(1), "Ko (chargé à la demande)");
const police = fs.readdirSync("public/police");
console.log("public/police —", police.length, "fichiers,",
  (police.reduce((a, f) => a + fs.statSync("public/police/" + f).size, 0) / 1024).toFixed(1), "Ko");
console.log("base :", cfg.url || "(aucune)");
