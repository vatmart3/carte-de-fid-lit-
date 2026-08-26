# Mettre la carte de fidélité en ligne

Objectif : une adresse web unique, le boucher encaisse depuis sa tablette,
chaque client consulte sa carte depuis son propre téléphone.

> **Le code d'accès du boucher.** En base en ligne, il n'y a plus de code à
> quatre chiffres : c'est l'e-mail et le mot de passe créés à l'étape 1.3.
> Le code `4726` ne vaut que pour la démonstration hors base.

Compter **une heure** la première fois. Coût : 0 € par mois (offres gratuites
Supabase + Vercel), 10 à 15 € par an si vous voulez un nom de domaine à vous.

---

## 1. Créer la base — Supabase

1. Sur https://supabase.com, créer un projet (région **Europe (Paris)** ou
   **Frankfurt** : les données restent en Europe, c'est ce qu'attend le RGPD).
   Noter le mot de passe de la base, il ne sera plus affiché.
   **Projet déjà créé ?** Vérifier la région dans **Settings → General →
   Region**. Si elle est américaine, mieux vaut recréer le projet en Europe :
   cela évite toute question de transfert hors Union européenne.
2. Ouvrir **SQL Editor** → **New query**, coller tout le contenu du fichier
   [`supabase/schema.sql`](supabase/schema.sql), puis **Run**.
   Le message attendu est « Success. No rows returned ».
3. Ouvrir **Authentication → Users → Add user**, créer le compte du boucher
   (e-mail + mot de passe), et cocher **Auto Confirm User**.
   Ce tout premier compte est **automatiquement** reconnu comme personnel :
   rien à recopier. Les comptes créés ensuite ne le sont pas.
4. Dans **Authentication → Providers → Email**, désactiver
   **Enable sign-ups**. Personne ne peut plus créer de compte de son côté.

Pour ajouter un second employé plus tard, créer son compte puis exécuter :

```sql
insert into public.staff (user_id, name)
select id, 'Prénom' from auth.users where email = 'son@adresse.fr';
```

> **Déjà fait pour ce dépôt.** `index.html` est configuré sur le projet
> `edgivtkpqyziucjyzffs`. Il reste les étapes 1, 3 et 4. Une fois le schéma
> installé, ouvrir Espace boucher → Réglages → Base en ligne →
> **Vérifier l'installation** : les quatre contrôles doivent être verts.

## 2. Relier l'application à la base

Pour un autre projet : ouvrir `index.html` et remplir le bloc de configuration,
en bas du fichier, juste avant les données :

```html
<script id="sbcfg" type="application/json">{"url":"https://xxxxxxxx.supabase.co","key":"eyJhbGciOi..."}</script>
```

Les deux valeurs sont dans Supabase → **Settings → API** :

| Champ | Valeur Supabase |
|---|---|
| `url` | **Project URL** |
| `key` | **Publishable key** (`sb_publishable_…`), ou l'ancienne **anon public** |

> La clé `anon` est faite pour être publique : elle est présente dans le code de
> toutes les applications web de ce type. Ce qui protège les données, ce sont
> les règles installées par `schema.sql`, testées pour ça. **Ne jamais mettre la
> clé `service_role`** dans le fichier : celle-là ouvre tout.

Pour essayer avant de modifier le fichier : ouvrir l'appli, Espace boucher →
Réglages → **Base en ligne**, coller les deux valeurs. Attention, cet
enregistrement ne vaut que pour l'appareil utilisé — pour les clients, les
valeurs doivent être **dans le fichier**.

## 3. Publier le site — Vercel

Le dépôt est prêt pour Vercel : `vercel.json` et `scripts/build-site.mjs`
publient **uniquement** `index.html`. Le schéma, les scripts, la démo et la
documentation restent dans le dépôt, hors de l'hébergement public.

1. Aller sur https://vercel.com/new
2. **Import Git Repository** → connecter GitHub → choisir `carte-de-fid-lit-`
3. Ne rien changer : la configuration est lue dans `vercel.json`
   (aucune dépendance, aucun framework, dossier publié `public/`)
4. **Deploy**. L'adresse arrive en une minute, du type
   `carte-de-fid-lit.vercel.app` — modifiable dans **Settings → Domains**.

Chaque `git push` redéploie ensuite le site automatiquement.

Sans passer par GitHub, depuis le dossier du projet :

```sh
npx vercel --prod
```

### En-têtes de sécurité

`vercel.json` installe aussi une politique de contenu (CSP) qui n'autorise la
page à contacter que **ce projet Supabase**, et interdit tout le reste — y
compris les serveurs de Google, puisque la police est maintenant hébergée avec
le site. Elle a été testée avec l'application complète avant livraison.
En cas de changement de projet Supabase, mettre à jour l'adresse dans
`connect-src`, sinon la page ne pourra plus joindre la base.

### Nom de domaine (facultatif)

Acheter `fidelite-boucherie-xxx.fr` (OVH, Gandi, Infomaniak : ~12 €/an), puis
Vercel → **Settings → Domains → Add**. Le certificat HTTPS est automatique.

### Autres hébergeurs

C'est un fichier statique : Netlify (glisser `index.html` sur
https://app.netlify.com/drop), Cloudflare Pages, GitHub Pages ou un
hébergement mutualisé classique conviennent aussi. Seul Vercel lit
`vercel.json` ; ailleurs, les en-têtes de sécurité sont à reporter dans la
configuration de l'hébergeur.

## 4. Reprendre les données existantes

Si des fiches ont déjà été saisies dans la version hors ligne :
Réglages → Données → **Sauvegarde (JSON)** sur l'ancienne version, puis
Réglages → Données → **Restaurer** sur la nouvelle. Les fiches, l'historique,
les parrainages et les numéros de carte sont conservés.

## 5. Au comptoir

- **Le boucher** ouvre le site, Espace boucher, se connecte une fois : sa
  tablette reste connectée. Onglet **Encaisser**, il saisit le numéro de carte
  et le montant.
- **Le client** reçoit un lien personnel à la création de sa carte
  (`…/?c=xxxx`). À ajouter en favori ou sur l'écran d'accueil du téléphone.
  S'il le perd : bouton **J'ai déjà une carte**, téléphone + date de naissance.

Imprimer un petit carton au comptoir avec le QR code de l'adresse du site et la
mention « Créez votre carte en 30 secondes » : n'importe quel générateur de QR
code en ligne fait l'affaire à partir de l'adresse du site.

---

## 4 bis. Le scanner

Le bouton **Scanner** de l'écran d'encaissement ouvre l'appareil photo du
boucher. Trois conditions :

1. **Le site doit être en HTTPS** — c'est le cas sur Vercel, automatiquement.
2. **Le navigateur demande l'autorisation** la première fois. Il faut accepter ;
   si on refuse par erreur, l'autorisation se rétablit dans les réglages du
   navigateur, à la ligne du site.
3. **`scanner.js` doit être déposé à côté de `index.html`** — la configuration
   Vercel du dépôt s'en charge. Si vous déployez à la main, copiez
   `vendor/jsqr.min.js` sous le nom `scanner.js` dans le même dossier.

Si l'appareil photo est indisponible, le scanner propose de **prendre une photo
du code**, ce qui marche partout. Et le numéro de carte reste saisissable au
clavier : le scanner fait gagner du temps, il n'est jamais un passage obligé.

### Pourquoi le scan ne marche pas sur la démonstration

Sur la démonstration hébergée chez Claude, la page tourne **dans un cadre isolé
(iframe) qui ne reçoit pas l'autorisation caméra**. Aucun réglage, aucune
correction de code ne peut y changer quoi que ce soit : le navigateur refuse
l'accès avant même que l'application demande. Le bouton **Prendre une photo du
code** y prend le relais, et le numéro reste saisissable au clavier.

Pour essayer la caméra **avant** la mise en ligne définitive :

```bash
node scripts/build-essai.mjs
```

produit `dist/carte-essai.html` — l'application entière dans un fichier unique,
lecteur de codes compris, sans aucune base branchée. Déposez ce fichier sur
[app.netlify.com/drop](https://app.netlify.com/drop) (glisser-déposer, pas de
compte à créer) : vous obtenez une adresse en HTTPS, vous l'ouvrez sur le
téléphone, et le scan s'ouvre pour de vrai. Ce fichier ne touche à rien : il ne
connaît pas votre base Supabase.

Une fois le site publié sur Vercel (partie 3), la question ne se pose plus : la
page est en pleine fenêtre, en HTTPS, et la caméra s'ouvre au premier appui.

## 4 ter. La signature du client

Depuis l'inscription, le client **signe du doigt dans une case blanche**, que la
carte soit créée par lui-même sur son téléphone ou par le boucher au comptoir.
Sans signature ni case d'accord cochée, la carte n'est pas créée.

Ce n'est pas une image : l'application enregistre le **tracé** (quelques
centaines d'octets), ce qui reste net à toutes les tailles et ne pèse rien dans
la base. La signature reste affichée sur le compte du client, apparaît sur sa
fiche côté boucher, part avec l'export de ses données, et disparaît avec elles
s'il supprime sa carte.

Les fiches créées avant cette version n'ont pas de signature. Réglages →
Données personnelles indique combien il en reste ; ouvrez la fiche du client à
son prochain passage et utilisez **Faire signer**. Le client peut aussi le faire
lui-même depuis sa carte.

## 4 quater. Écrire à une partie des clients

Dans **Clients**, un carré à cocher précède chaque nom. Cochez qui vous voulez —
ou **Tout cocher**, qui ne prend que les fiches actuellement affichées : tapez
d'abord une recherche pour restreindre la liste, puis cochez tout.

Le bandeau noir qui apparaît propose **Écrire à ces clients**. La fenêtre
demande d'abord la **nature** du message, et c'est le point important :

- **Message de service** — commande prête, horaires, fermeture. Cela répond à
  une demande du client : tout le monde peut le recevoir.
- **Offre commerciale** — arrivage, promotion. La loi ne permet de l'envoyer
  qu'aux clients qui ont coché la case « j'accepte de recevoir les offres ».
  L'application **retire les autres d'elle-même** et affiche leurs noms, pour
  que vous sachiez qui n'est pas parti.

Ensuite : un modèle si vous voulez, votre texte, et trois sorties — **SMS**,
**e-mail** (les adresses en copie cachée, personne ne voit celles des autres),
ou **copier les numéros**. Dans les trois cas l'application ne fait qu'ouvrir
votre application de messages avec tout déjà rempli : c'est vous qui relisez et
qui appuyez sur envoyer. La carte de fidélité n'a aucun service d'envoi, et ne
transmet donc rien à personne.

Deux limites pratiques : au-delà d'environ vingt numéros, certains téléphones
refusent d'ouvrir le SMS — envoyez en deux fois ; et au-delà de 160 caractères,
l'opérateur facture deux SMS. Le compteur de caractères le rappelle.

Chaque envoi laisse une ligne dans le journal : la nature, la voie, le nombre
de destinataires et le nombre d'écartés. Ni les noms, ni le texte.

## 4 quinquies. Envoyer vraiment, par Brevo (facultatif)

Par défaut, l'application prépare le message et ouvre votre application de
messages : c'est vous qui appuyez sur envoyer. Avec **Brevo**, elle envoie
elle-même, au nom de la boutique, sans passer par votre téléphone.

### Pourquoi ce n'est pas un simple champ à remplir

La clé d'API Brevo donne le droit d'envoyer des courriels et des SMS **depuis
votre compte, à vos frais**. Une page web est lisible par n'importe qui : le
menu « afficher le code source » suffit. Y coller la clé reviendrait à la
publier, et n'importe quel visiteur pourrait vider votre crédit SMS.

La clé reste donc sur un serveur — une **fonction Supabase**, qui reçoit la
demande du boucher, vérifie qu'il est bien du personnel, relit les fiches en
base, refait le tri du consentement, et seule appelle Brevo.

### Ce qu'il faut faire, une fois

**1. Créer un compte Brevo** sur [brevo.com](https://www.brevo.com) et récupérer
la clé d'API : Paramètres → **SMTP & API** → onglet **Clés d'API** → *Générer
une nouvelle clé*. Elle commence par `xkeysib-`.

**2. Vérifier l'adresse d'expédition** dans Brevo (Expéditeurs, domaines &
adresses IP). Sans cela les courriels partent en indésirables. Pour les SMS,
déclarer un **nom d'expéditeur** de 11 caractères maximum — en France c'est
obligatoire.

**3. Installer les outils Supabase** sur votre ordinateur :

```bash
npm install -g supabase
supabase login
supabase link --project-ref edgivtkpqyziucjyzffs
```

**4. Poser la clé en secret** — elle ne quitte jamais Supabase :

```bash
supabase secrets set BREVO_KEY=xkeysib-votre-cle-ici
```

**5. Publier la fonction** :

```bash
supabase functions deploy envoyer
```

**6. Dans l'application**, Réglages → **Envoi automatique** : l'adresse
d'expédition, le nom affiché, le nom court des SMS, et l'adresse du site
(elle sert au lien de désinscription). Puis **Vérifier la connexion** : si tout
est en place, l'application le dit. Sinon elle nomme ce qui manque.

### Ce que la fonction refuse de faire

- Envoyer si l'appelant n'est pas dans la table `staff` — même avec une clé
  valide, même en trafiquant la page.
- Faire confiance à la liste d'adresses envoyée par le navigateur : elle ne
  reçoit que des **numéros de carte** et relit tout en base.
- Envoyer une offre commerciale à qui ne l'a pas acceptée. Le tri existe déjà
  dans la page ; il est **refait sur le serveur**, parce qu'un filtre côté
  navigateur ne protège personne.
- Partir sans lien de désinscription sur une offre : chaque courriel porte le
  lien de la carte de **son** destinataire.
- Dépasser 300 destinataires, ou 100 SMS, en un seul envoi.

### Ce que ça coûte

Les courriels sont compris dans l'offre gratuite de Brevo — **300 par jour**.
Les **SMS sont facturés à l'unité** (de l'ordre de 4 à 5 centimes en France,
et un message de plus de 160 caractères en compte deux). L'application demande
confirmation avant tout envoi de SMS et affiche le crédit restant après coup.

### Si vous n'installez rien

Tout continue de fonctionner : l'application ouvre votre application de
messages avec les destinataires et le texte remplis. Brevo n'est qu'un confort.

## 5. Se mettre en règle (RGPD)

Une fois le site en ligne, ouvrir **Réglages → Données personnelles** et
compléter raison sociale, adresse, SIRET, directeur de la publication et
contact : ces informations alimentent les mentions légales et la politique de
confidentialité que les clients peuvent consulter. Tant qu'elles sont vides,
les pages affichent « à compléter », ce qui n'est pas conforme.

Le reste — registre des traitements, contrats de sous-traitance, affichette au
comptoir, conduite à tenir en cas de fuite — est détaillé dans
[RGPD.md](RGPD.md), avec un registre prérempli à imprimer.

## Vérifier que tout est bien fermé

Espace boucher → Réglages → Base en ligne → **Vérifier l'installation**.
Quatre contrôles, exécutés depuis le navigateur avec la clé publique :

1. le schéma répond et renvoie les réglages de la boutique ;
2. le fichier clients est **inaccessible** sans connexion ;
3. l'encaissement est **refusé** à un visiteur ;
4. le compte connecté est bien inscrit dans `staff`.

Un contrôle rouge indique précisément quelle étape reprendre. À relancer après
toute modification du schéma.

## Ce que la base garantit

Les règles installées par `schema.sql` ont été exécutées et vérifiées sur
PostgreSQL 16 avant livraison :

| Qui | Peut | Ne peut pas |
|---|---|---|
| Un visiteur | Voir le barème, créer sa carte, consulter **sa** carte via son lien | Lire le fichier clients, deviner le lien d'un autre, s'attribuer des points |
| Un compte connecté hors personnel | Rien | Tout le reste |
| Le boucher (inscrit dans `staff`) | Tout le fichier, encaissements, récompenses, réglages | — |

Les points ne sont jamais calculés par le navigateur : montant × barème,
bienvenue, parrainage, anniversaire sont appliqués par la base elle-même.
Le cadeau d'anniversaire est bloqué à un par an et par client, une récompense
est refusée si le solde est insuffisant.

## Sauvegardes

Supabase sauvegarde quotidiennement sur les offres payantes. Sur l'offre
gratuite, prendre l'habitude d'un export : Réglages → Données →
**Sauvegarde (JSON)**, une fois par mois, conservé ailleurs.

## Coûts et limites de l'offre gratuite Supabase

500 Mo de base et 5 Go de trafic par mois : pour une boucherie, cela représente
des dizaines de milliers de clients et d'achats. Un projet gratuit est mis en
pause après une semaine sans aucune requête — sans objet pour une boutique qui
s'en sert tous les jours.
