// Génère le jeu de données de démonstration (déterministe).
// node scripts/seed.mjs  ->  JSON sur stdout
let s = 20260824;
const rnd = () => (s = (s * 1103515245 + 12345) % 2147483648) / 2147483648;
const pick = a => a[Math.floor(rnd() * a.length)];
const ri = (a, b) => a + Math.floor(rnd() * (b - a + 1));
const TODAY = new Date('2026-08-24T12:00:00Z');
const dayStr = d => new Date(TODAY.getTime() - d * 864e5).toISOString().slice(0, 10);

const SHOP = {
  name: "Boucherie Sept-la-Ville",
  city: "Sept-la-Ville",
  tagline: "Artisan boucher — viandes de pays",
  ppe: 1,          // points par euro
  welcome: 20,
  birthday: 50,
  godfather: 50,
  godchild: 25,
  rewards: [
    { p: 100, label: "500 g de merguez maison offerts" },
    { p: 200, label: "10 € de remise sur votre achat" },
    { p: 350, label: "Un poulet fermier offert" },
    { p: 500, label: "Plateau apéritif charcuterie offert" },
    { p: 800, label: "30 € de remise + le colis du boucher" }
  ],
  tiers: [
    { min: 0, label: "Nouveau" },
    { min: 300, label: "Fidèle" },
    { min: 800, label: "Habitué" },
    { min: 1500, label: "Ambassadeur" }
  ]
};

const PEOPLE = [
  ["Nadia Belkacem", "0612480377", "nadia.belkacem@example.fr", "1985-03-12"],
  ["Jean-Pierre Marchand", "0687112094", "", "1962-11-04"],
  ["Sofia Ramos", "0755201388", "sofia.ramos@example.fr", "1991-08-27"],
  ["Thérèse Aubry", "0645930211", "", "1949-05-19"],
  ["Karim Ould", "0699421750", "karim.ould@example.fr", "1988-08-30"],
  ["Marie Lefevre", "0633870142", "m.lefevre@example.fr", "1976-01-23"],
  ["Antoine Duclos", "0611903466", "", "1994-09-08"],
  ["Fatou Diallo", "0781224509", "fatou.d@example.fr", "1983-12-15"],
  ["Gilbert Sanchez", "0620558741", "", "1957-08-06"],
  ["Hélène Prieur", "0764310928", "helene.prieur@example.fr", "1970-06-30"],
  ["Mehdi Nasri", "0652118840", "", "1996-02-11"],
  ["Christine Vasseur", "0627704513", "c.vasseur@example.fr", "1968-10-02"],
  ["Lucas Berthier", "0745662301", "", "1999-08-25"],
  ["Aminata Sow", "0698330176", "aminata.sow@example.fr", "1980-04-17"],
  ["Roger Delaunay", "0632901488", "", "1953-07-21"],
  ["Julie Caron", "0711458620", "julie.caron@example.fr", "1990-08-24"]
];

const BASKETS = [
  "Bavette, merguez", "Côte de bœuf", "Poulet fermier, lardons",
  "Épaule d'agneau", "Brochettes, chipolatas", "Steak haché x6",
  "Rôti de veau", "Saucisson, jambon", "Escalopes de dinde",
  "Gigot d'agneau", "Entrecôte, frites maison", "Plat préparé : tajine",
  "Boudin blanc, pâté", "Filet mignon de porc", "Merguez, brochettes, charbon"
];

const initials = n => n.split(" ").map(w => w[0]).join("").slice(0, 2).toUpperCase();
const code = (n, id) => n.split(" ")[0].normalize("NFD").replace(/[^A-Za-z]/g, "").slice(0, 3).toUpperCase() + "-" + id;

const clients = [];
let seq = 1000;
PEOPLE.forEach((p, i) => {
  const id = String(++seq);
  const age = ri(20, 400);              // ancienneté en jours
  const nb = Math.max(1, Math.round(age / ri(5, 16)));
  const hist = [];
  let lifetime = 0, spent = 0, points = 0, visits = 0;
  hist.push({ t: dayStr(age), a: 0, p: SHOP.welcome, w: "Bienvenue — carte créée", k: "welcome" });
  lifetime += SHOP.welcome; points += SHOP.welcome;
  const days = [];
  for (let j = 0; j < nb; j++) days.push(ri(0, age - 1));
  days.sort((a, b) => b - a);
  days.forEach(d => {
    const a = Math.round((ri(1200, 9500) / 100) * 100) / 100;
    const pts = Math.round(a * SHOP.ppe);
    hist.push({ t: dayStr(d), a, p: pts, w: pick(BASKETS), k: "buy" });
    lifetime += pts; points += pts; spent += a; visits++;
  });
  // récompense utilisée pour les gros cumuls
  if (points > 260 && rnd() > .45) {
    const r = SHOP.rewards[0];
    hist.push({ t: dayStr(ri(1, Math.min(age, 60))), a: 0, p: -r.p, w: r.label, k: "reward" });
    points -= r.p;
  }
  hist.sort((x, y) => (x.t < y.t ? 1 : -1));
  clients.push({
    id, name: p[0], phone: p[1], email: p[2], bday: p[3],
    created: dayStr(age), points, lifetime, spent: Math.round(spent * 100) / 100,
    visits, code: code(p[0], id), by: "", demo: true, hist
  });
});
// parrainages de démo
const link = (child, parent) => {
  const c = clients.find(x => x.id === child), p = clients.find(x => x.id === parent);
  c.by = p.id;
  c.hist.push({ t: c.created, a: 0, p: SHOP.godchild, w: "Parrainé par " + p.name, k: "ref" });
  c.points += SHOP.godchild; c.lifetime += SHOP.godchild;
  p.hist.push({ t: c.created, a: 0, p: SHOP.godfather, w: "Parrainage de " + c.name, k: "ref" });
  p.points += SHOP.godfather; p.lifetime += SHOP.godfather;
  c.hist.sort((x, y) => (x.t < y.t ? 1 : -1)); p.hist.sort((x, y) => (x.t < y.t ? 1 : -1));
};
link("1005", "1001"); link("1008", "1001"); link("1011", "1003"); link("1013", "1006");

const state = {
  v: 1, shop: SHOP, admin: { pin: "4726" }, seq,
  clients,
  log: [
    { t: dayStr(0), m: "Encaissement 42,50 € — n° 1001" },
    { t: dayStr(1), m: "Carte n° 1016 créée" },
    { t: dayStr(3), m: "Récompense utilisée — n° 1004" }
  ],
  meta: { seeded: true, built: "2026-08-24" }
};
process.stdout.write(JSON.stringify(state));
