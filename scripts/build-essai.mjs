// Produit dist/carte-essai.html : l'application entière dans un seul fichier,
// avec le lecteur de QR embarqué et un jeu de démonstration.
//
// À quoi ça sert : la vitrine publiée tourne dans un cadre (iframe) qui
// n'autorise pas la caméra — le scan ne peut pas y fonctionner, quoi qu'on
// fasse. Ce fichier-ci, déposé sur n'importe quel hébergement statique
// (Netlify Drop, Vercel, un dossier public), s'ouvre en pleine page : la
// caméra du téléphone est alors joignable et le scan se teste pour de vrai.
//
// Aucune base de production n'y est branchée : il ne touche à rien.
import fs from "node:fs";

const src = fs.readFileSync("index.html", "utf8");

const noCfg = t => t.replace(
  /(<script id="sbcfg" type="application\/json">)[\s\S]*?(<\/script>)/,
  '$1{"url":"","key":""}$2');

const withDemo = t => t.replace(
  /(<script id="db" type="application\/json">)[\s\S]*?(<\/script>)/,
  (m, a, z) => a + fs.readFileSync("demo/demo.json", "utf8").trim() + z);

// Le décodeur voyage normalement à côté de la page ; ici il doit être dedans.
const withDecoder = t => t.replace(
  '<script id="appjs">',
  '<script id="qrdec">' + fs.readFileSync("vendor/jsqr.min.js", "utf8") + '<\/script>\n<script id="appjs">');

// Les polices sont hébergées avec le site ; un fichier isolé n'a pas de
// dossier « police/ » à côté de lui, alors il repasse par la feuille distante.
const GF = '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n' +
  '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zen+Kaku+Gothic+New:wght@400;500;700&display=swap">';
const distantFonts = t => t
  .replace(/<style id="fontface">[\s\S]*?<\/style>/, GF)
  .replace(/^\s*<link rel="preload"[^>]*>\s*\n/gm, "");

fs.mkdirSync("dist", { recursive: true });
const out = withDecoder(withDemo(noCfg(distantFonts(src))));
fs.writeFileSync("dist/carte-essai.html", out);
console.log("dist/carte-essai.html —", (out.length / 1024).toFixed(1), "Ko");
