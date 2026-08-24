// Produit dist/artifact.html : la même application, sans l'enveloppe
// <html>/<head>/<body> — format attendu par la publication en ligne.
// Attention : le script applicatif contient lui-même les chaînes "</body>"
// et "</html>" (il sait se régénérer), d'où le découpage par bornes et non
// par expression régulière paresseuse.
import fs from "node:fs";
const src = fs.readFileSync("index.html", "utf8");
const head = src.slice(src.indexOf("<head>") + 6, src.indexOf("</head>"));
const body = src.slice(src.indexOf("<body>") + 6, src.lastIndexOf("</body>"));
// Attention : la démo publiée accumule les données saisies en ligne. Avant de
// la republier, récupérer son bloc <script id="db"> et le réinjecter ici,
// sinon la republication écrase ce qui a été saisi.
// La démo publiée en ligne tourne sur son propre stockage : on neutralise la
// configuration de base de production, qui n'a rien à y faire.
const noCfg = b => b.replace(
  /(<script id="sbcfg" type="application\/json">)[\s\S]*?(<\/script>)/,
  '$1{"url":"","key":""}$2');

const keep = head
  .split("\n")
  .filter(l => !/^\s*<meta /.test(l))   // charset / viewport / color-scheme : fournis par l'hôte
  .join("\n")
  .trim();
fs.mkdirSync("dist", { recursive: true });
fs.writeFileSync("dist/artifact.html", keep + "\n" + noCfg(body.trim()) + "\n");
console.log("dist/artifact.html —", (fs.statSync("dist/artifact.html").size / 1024).toFixed(1), "Ko");
