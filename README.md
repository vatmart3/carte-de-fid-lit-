# La Carte du Boucher

Carte de fidélité pour une boucherie : côté client une carte à points, côté
boucher un espace d'encaissement et de statistiques. Tout tient dans une seule
page autonome — aucun serveur à installer.

**Démo en ligne :** https://claude.ai/code/artifact/5dfed855-fac8-4e64-895c-2cf7f198fd90
**Code d'accès boucher :** `4726` (modifiable dans Réglages → Code d'accès)
**Mise en production :** [DEPLOIEMENT.md](DEPLOIEMENT.md) — Supabase + Vercel, une heure.
**Conformité :** [RGPD.md](RGPD.md) — ce que l'application assure, ce qui reste à la charge de la boutique.

---

## Côté client

| | |
|---|---|
| **Créer ma carte** | Nom, téléphone, date de naissance obligatoires ; e-mail et code parrain facultatifs. Case d'accord explicite avant enregistrement. |
| **Numéro de carte** | Attribué automatiquement à partir de 1001. C'est ce numéro que le client donne en caisse. |
| **Ma carte** | Solde de points, statut (Nouveau → Fidèle → Habitué → Ambassadeur), jauge vers la prochaine récompense, liste des récompenses débloquées et verrouillées, historique complet des achats (date, détail, montant, points), compteurs (passages, total dépensé, points cumulés). |
| **Anniversaire** | Jour et mois seulement — l'année n'est jamais demandée. Rappel affiché le mois venu ; le boucher crédite le cadeau en un clic. |
| **Code à scanner** | Chaque carte porte un QR code, affiché sous le solde. Le boucher le scanne pour ouvrir directement l'encaissement de ce client. Le code contient le numéro de carte, jamais le lien personnel : une photo de la carte n'ouvre pas le compte. |
| **Mes données** | Le client corrige ses informations, télécharge tout son dossier, accepte ou refuse les offres, et supprime sa carte — lui-même, sans passer par la boutique. |
| **Parrainage** | Chaque client a un code personnel (`NAD-1001`). Le filleul le saisit à l'inscription : les deux sont crédités automatiquement. |

Le client retrouve sa carte avec son numéro **ou** son téléphone. Son appareil
la mémorise ensuite.

L'espace boucher est toujours derrière le mot de passe : aucun passage direct
depuis la carte d'un client, et la session se verrouille seule après un délai
d'inactivité réglable (quinze minutes par défaut). Le verrouillage efface la
session côté navigateur — ce n'est pas qu'un rideau devant l'écran.

## Côté boucher

| Onglet | Contenu |
|---|---|
| **Tableau de bord** | Nombre de clients (+ nouveaux du mois), passages, encaissé total et mensuel, panier moyen, points en circulation, récompenses utilisées. Graphique de l'encaissé sur 14 jours, meilleurs clients, journal des opérations, alerte sur les clients sans passage depuis plus de 3 mois. **Pourquoi ils viennent** : le compte des raisons de venue sur 3 mois — la seule mesure qui dit si les SMS rapportent plus qu'ils ne coûtent. |
| **Encaisser** | Écran de terminal de paiement. **Scanner** : l'appareil photo lit le code du client et ouvre sa fiche ; repli par photo si la caméra est refusée. Sinon **Numéro** ou **Nom** : le champ bascule entre clavier chiffres et clavier lettres, et les clients correspondants sont proposés dès les premiers caractères (nom, n° de carte, téléphone, points ; accents et nom de famille compris), flèches + Entrée au clavier. Puis pavé numérique — les chiffres entrent par la droite, en centimes, comme sur un terminal bancaire — avec les points à créditer affichés en direct, et une **raison de la venue** en un appui (Habitué, A reçu le SMS, Nouveau client, Bouche à oreille, Passait devant, Pour une récompense). Bouton accroché au bas de l'écran, fermé tant qu'aucun montant n'est tapé ; la caisse se vide après validation. Récompense disponible et cadeau d'anniversaire proposés au même endroit. |
| **Clients** | Fichier complet, recherche instantanée, tris, statut d'activité. Fiche détaillée : historique, encaissement, utilisation d'une récompense, ajout/retrait manuel de points avec motif, modification, suppression. Création de carte au comptoir. Cases à cocher devant chaque nom : la sélection ouvre **Écrire à ces clients** (le filtre du consentement s'applique aux offres commerciales), **Exporter (CSV)** et **Exporter pour Brevo** — format d'import Brevo, téléphones en `33…`, consentants seulement. |
| **Anniversaires** | Ceux du mois (avec repérage du jour même) et ceux du mois suivant, pour anticiper. Cadeau limité à une fois par an et par client. |
| **Parrainage** | Qui a parrainé qui, chiffre d'affaires apporté par les filleuls, points distribués. |
| **Réglages** | Nom / ville / accroche de la boutique, barème (points par euro, bienvenue, anniversaire, parrain, filleul), verrouillage automatique, éditeur de récompenses, compte d'accès, export CSV clients et achats, sauvegarde et restauration JSON. |
| **Données personnelles** | Identité légale de la boutique (alimente les mentions légales et la politique de confidentialité), durée de conservation, signalement et purge des fiches trop anciennes, contrôle de l'installation. |

## Barème par défaut

1 point par euro dépensé · 20 points de bienvenue · 50 points d'anniversaire ·
parrainage 50 / 25 points.

| Points | Récompense |
|---:|---|
| 100 | 500 g de merguez maison offerts |
| 200 | 10 € de remise sur l'achat |
| 350 | Un poulet fermier offert |
| 500 | Plateau apéritif charcuterie offert |
| 800 | 30 € de remise + le colis du boucher |

Tout est modifiable dans Réglages, y compris le nom de la boutique (la démo est
paramétrée sur « Boucherie Sept-la-Ville »).

## Où sont stockées les données

L'application détecte son environnement et choisit seule l'un des trois modes.
Le mode actif est indiqué en bas de chaque page et dans Réglages → Données.

**1. Base en ligne (Supabase) — le mode de production.** C'est celui à utiliser
en boutique : voir [DEPLOIEMENT.md](DEPLOIEMENT.md). Le boucher se connecte avec
un compte e-mail, chaque client reçoit un lien personnel (`…/?c=xxxx`) et
consulte sa carte depuis son propre téléphone. Les points sont calculés par la
base, jamais par le navigateur, et le fichier clients n'est lisible que par les
comptes inscrits dans la table `staff`.

**2. Base partagée (page publiée en ligne).** Chaque validation republie la page
avec les nouvelles données ; tous les appareils ouverts se mettent à jour. Bon
pour une démonstration, pas pour de vrais clients : ils sont en lecture seule et
les données sont lisibles dans le source de la page.

**3. Mode local.** Fichier ouvert directement ou hébergement statique sans base :
les données restent dans le navigateur de l'appareil (`localStorage`). Prévoir
une sauvegarde JSON régulière.

## Limites connues

**En mode base en ligne** (production) :

- Pas d'envoi automatique de SMS ni d'e-mail pour les anniversaires : la liste
  du mois est fournie, le geste reste manuel.
- Pas de lecture de QR code : le numéro de carte se saisit au clavier.
- Le fichier client est chargé en une fois à la connexion du boucher : parfait
  jusqu'à quelques milliers de fiches, à paginer au-delà.

**Sans base en ligne** (modes 2 et 3), à ne pas mettre entre les mains de vrais
clients : les données, téléphones et code d'accès compris, sont contenues dans
la page et lisibles par quiconque en ouvre le source. Le code d'accès protège
l'interface, pas les données.

## Modèle de données

En mode base en ligne, ce même modèle est réparti sur les tables `shop`,
`clients`, `moves`, `log` et `staff` (voir [`supabase/schema.sql`](supabase/schema.sql)).
Hors ligne, il tient dans un seul objet :

```jsonc
{
  "shop":   { "name", "city", "tagline", "ppe", "welcome", "birthday",
              "godfather", "godchild", "rewards": [{ "p", "label" }], "tiers": [] },
  "admin":  { "pin" },
  "seq":    1016,                       // dernier numéro de carte attribué
  "clients": [{
    "id": "1001", "name", "phone", "email", "bday", "created", "code",
    "points", "lifetime", "spent", "visits",
    "by": "1003",                       // parrain
    "hist": [{ "t": "2026-08-24", "a": 42.5, "p": 42, "w": "Bavette, merguez",
               "k": "buy" }]            // buy | reward | gift | ref | welcome | adj
  }],
  "log": [{ "t", "m" }]                 // journal boutique
}
```

## Développement

```sh
npx http-server . -p 8080     # puis http://localhost:8080
node scripts/seed.mjs         # régénère le jeu de démonstration (déterministe)
node scripts/build-artifact.mjs   # produit dist/artifact.html pour la démo publiée
```

`index.html` est le fichier de production : son bloc `sbcfg` pointe sur le
projet Supabase de la boutique, et c'est lui qu'on dépose sur l'hébergeur. Pour
essayer l'application sans base, vider ce bloc (`{"url":"","key":""}`) sur une
copie : elle repasse en mode local avec le jeu de démonstration. Le build de la
démo publiée le fait automatiquement.

- `index.html` — l'application complète, **base vide** : c'est le fichier de production, aucune fiche fictive.
- `demo/demo.json` — le jeu de démonstration, injecté uniquement dans la vitrine publiée.
- `supabase/schema.sql` — tables, règles d'accès et fonctions de la base en ligne.
- `DEPLOIEMENT.md` — mise en ligne pas à pas.
- `dist/artifact.html` — la même application sans l'enveloppe `<html>/<head>/<body>`, format attendu par l'hébergement en ligne. Généré, ne pas modifier à la main.
- `scripts/seed.mjs` — générateur du jeu de démonstration.
- `supabase/functions/envoyer/index.ts` — fonction Deno qui envoie les messages
  par Brevo. Elle existe pour une seule raison : la clé d'API ne peut pas vivre
  dans une page web, lisible par tous. Elle vérifie que l'appelant est du
  personnel, relit les destinataires en base plutôt que de croire le navigateur,
  refait le tri du consentement, et joint le lien de désinscription. Déploiement
  dans `DEPLOIEMENT.md`.
- `scripts/brevo.sh` — installe l'envoi Brevo en une commande : la clé est saisie
  à l'aveugle et transmise directement aux secrets Supabase, sans passer par le
  disque ni par l'historique du terminal.
- `scripts/build-essai.mjs` — produit `dist/carte-essai.html` : l'application
  entière dans un fichier unique, lecteur de QR compris, sans base branchée.
  Sert à essayer la caméra sur un vrai téléphone avant la mise en ligne — la
  vitrine publiée tourne dans un cadre qui n'a pas accès à l'appareil photo.
- `vercel.json` + `scripts/build-site.mjs` — publication : `index.html`,
  `scanner.js` et le dossier `police/`, avec les en-têtes de sécurité (CSP
  restreinte au seul projet Supabase, testée avec l'application complète).
- `assets/police/` — les six fichiers de la police Zen Kaku Gothic New
  (sous-ensembles latin et latin-ext, graisses 400/500/700, 33 Ko en tout,
  licence SIL OFL). Ils sont hébergés avec le site : aucune requête ne part
  chez Google, et le texte est à sa place dès le premier affichage. Une
  police de secours aux mêmes proportions est déclarée juste à côté, pour que
  rien ne bouge si les fichiers arrivent en retard.
- `vendor/jsqr.min.js` — lecteur de QR codes ([jsQR](https://github.com/cozmo/jsqr),
  licence Apache 2.0, texte dans `vendor/jsqr-LICENSE.txt`). Publié sous le nom
  `scanner.js` et **chargé uniquement quand le boucher ouvre le scanner** : il pèse
  plus lourd que toute l'application, les clients ne le téléchargent jamais.
  Le générateur de codes, lui, est écrit dans l'application ; ses matrices ont été
  comparées module par module à une implémentation de référence sur les dix
  versions utilisées.

Hébergement statique possible tel quel (GitHub Pages, Netlify, OVH…) : déposer
`index.html`, l'application tourne alors en mode local.
