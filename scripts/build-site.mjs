// Prépare le dossier publié : uniquement la page de l'application.
// Le reste du dépôt (schéma, scripts, démo, documentation) n'a rien à faire
// sur l'hébergement public.
import fs from "node:fs";
fs.rmSync("public", { recursive: true, force: true });
fs.mkdirSync("public", { recursive: true });
fs.copyFileSync("index.html", "public/index.html");
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
console.log("base :", cfg.url || "(aucune)");
