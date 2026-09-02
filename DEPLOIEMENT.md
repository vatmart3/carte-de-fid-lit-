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

   > **L'ordre n'a pas d'importance.** Si le compte a été créé *avant*
   > l'installation du schéma, l'inscription automatique n'existait pas encore
   > pour lui : il se connecte alors sans rien voir, ni clients ni
   > encaissement. Rejouer `schema.sql` suffit — il rattrape le compte le plus
   > ancien du projet. L'application le détecte de son côté et affiche l'écran
   > *« Ce compte n'a pas encore les droits »*, avec la ligne à coller.
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

**1. Créer le compte Vercel avec GitHub.** https://vercel.com → *Sign Up* →
**Continue with GitHub**. S'inscrire ainsi fait la liaison des deux comptes du
même geste, il n'y a rien à relier ensuite. Choisir le plan **Hobby**, gratuit,
et déclarer un usage personnel.

**2. Donner accès au dépôt.** GitHub demande d'autoriser Vercel, puis *sur
quels dépôts*. Prendre **Only select repositories** → `carte-de-fid-lit-` →
*Install*. Plus prudent que « tous les dépôts » : Vercel ne voit que celui-ci.

**3. Importer.** https://vercel.com/new → le dépôt apparaît dans la liste →
**Import**.

**4. Ne rien changer.** L'écran de configuration se remplit tout seul depuis
`vercel.json` : *Framework Preset* sur **Other**, la commande de construction
et le dossier publié déjà écrits. **Aucune variable d'environnement à saisir** :
l'adresse de la base et sa clé publique sont dans le fichier lui-même, et la
clé Brevo vit chez Supabase, pas ici.

**5. Deploy.** Une minute. L'adresse arrive, du type
`carte-de-fid-lit.vercel.app` — modifiable dans **Settings → Domains**.

**6. Vérifier.** Ouvrir l'adresse : la page d'accueil doit s'afficher. Puis
Espace boucher → se connecter → Réglages → **Vérifier l'installation**.

Le dépôt ne contient qu'**une seule branche**, et c'est la branche par défaut :
Vercel la prend comme branche de production sans rien demander. Chaque `git
push` redéploie ensuite le site automatiquement, en une minute environ.

#### Savoir ce qui est réellement en ligne

**Espace boucher → Réglages**, tout en bas : *Version en ligne*, avec la date de
publication et le numéro du commit. C'est la seule façon de répondre sans
doute à « est-ce que ma modification est arrivée ? » — sinon on recharge à
l'aveugle et on suppose.

Si cette date ne bouge pas après un `git push`, ce n'est pas le navigateur, la
publication n'a pas eu lieu : Vercel → votre projet → onglet **Deployments**.
Le dernier déploiement porte le message du commit. En rouge, ouvrez-le, le
journal dit à quelle ligne la construction a échoué. Absent, c'est que Vercel
ne suit pas cette branche : **Settings → Git → Production Branch**, à régler
sur `claude/loyalty-program-site-1u5am8`.

#### Si le dépôt n'apparaît pas dans la liste

L'application GitHub de Vercel n'y a pas accès. Deux chemins vers le même
réglage : Vercel → *Settings → Git → Manage GitHub App*, ou GitHub →
*Settings → Applications → Vercel → Configure* → ajouter le dépôt.

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

### Brancher un nom de domaine acheté chez IONOS

Le site vit chez **Vercel**, le nom de domaine chez **IONOS**. Brancher l'un
sur l'autre, c'est dire à IONOS : « quand on demande cette adresse, réponds
l'adresse de Vercel ». Rien ne bouge chez Vercel, tout se règle chez IONOS,
en deux enregistrements.

**Avant de commencer**, le site doit déjà être publié sur Vercel (étapes
ci-dessus) et fonctionner sur son adresse `…vercel.app`. Sans cela il n'y a
rien à désigner.

Gardez **deux onglets ouverts** : le tableau de bord Vercel et celui d'IONOS.

**1. Déclarer le domaine chez Vercel.** Projet → **Settings → Domains** →
taper `boucherie-vatuone.fr` → **Add**. Vercel propose d'ajouter aussi la
version `www` : acceptez les deux. Il affiche alors *Invalid Configuration*
— c'est normal, rien n'est encore fait chez IONOS — **avec les deux
enregistrements exacts à créer**. Ne fermez pas cette page : c'est elle qui
fait foi, pas ce document.

**2. Libérer le domaine chez IONOS.** Menu **Domaines & SSL** → repérer le
domaine. Si la colonne *Utilisation* ou *Destination* montre un site IONOS,
une page de garde ou une redirection, il faut la retirer : menu **⋮** →
*Adapter la destination* → choisir *Aucune destination*. **Sans cela IONOS
réécrit vos enregistrements** et le branchement ne tiendra pas.

**3. Ouvrir les enregistrements.** Sur la même ligne : **⋮ → DNS** (ou cliquer
le domaine puis l'onglet *DNS*). La liste des enregistrements s'affiche.

**4. L'adresse principale.** Chercher la ligne de type **A** dont le nom est
`@` (parfois vide, parfois le domaine lui-même) → crayon → remplacer la valeur
par **l'adresse IP affichée par Vercel** à l'étape 1 (au moment où ceci est
écrit, Vercel donne `76.76.21.21` — mais **fiez-vous à son écran**, pas à ce
chiffre). TTL : 1 heure, ou 5 minutes le temps des essais. Enregistrer.
S'il n'y a aucune ligne `A` sur `@`, la créer.

**5. L'adresse en `www`.** Chercher une ligne nommée **www** :

- si c'est déjà un **CNAME**, remplacer sa valeur par `cname.vercel-dns.com` ;
- si c'est un **A**, le supprimer et créer un **CNAME** à la place.

Type `CNAME`, nom `www`, valeur `cname.vercel-dns.com`, TTL 1 heure.

**6. Faire le ménage, mais pas trop.** Supprimer les autres lignes **A**,
**AAAA** ou **CNAME** portant sur `@` ou `www` qui pointent encore vers IONOS.
En revanche **ne touchez pas** aux lignes **MX** ni aux **TXT** : ce sont vos
courriels et leur authentification. Les supprimer couperait la messagerie du
domaine.

**7. Attendre, puis vérifier.** Retour sur la page *Domains* de Vercel →
**Refresh**. Le plus souvent quelques minutes, parfois quelques heures. Quand
les deux lignes affichent *Valid Configuration* en vert, c'est branché :
Vercel installe le certificat HTTPS tout seul, il n'y a rien à acheter ni à
renouveler.

**8. Choisir l'adresse principale.** Toujours dans *Domains*, désigner celle
des deux qui est la vraie ; l'autre redirigera dessus. Prenez la version
**sans `www`** : c'est celle qui ira sur le carton du comptoir et dans le QR
code, autant qu'elle soit courte.

**9. Le dire à l'application.** Réglages → **Envoi automatique** → *Adresse du
site* → la nouvelle adresse, puis **Vérifier la connexion**. C'est elle qui
construit le lien de désinscription au bas des offres envoyées par Brevo.

**10. Refaire le carton du comptoir** avec le QR code de la nouvelle adresse.
Les liens déjà donnés aux clients continuent de fonctionner : Vercel garde
l'ancienne adresse `…vercel.app` en service, personne ne perd sa carte.

Rien d'autre n'est à changer dans l'application : les liens des cartes et le
QR code sont construits à partir de l'adresse par laquelle on arrive, jamais
d'une adresse écrite en dur.

#### Si ça ne prend pas

| Ce que vous voyez | Ce que c'est |
|---|---|
| Vercel reste sur *Invalid Configuration* après plusieurs heures | Le domaine est resté « connecté » à un produit IONOS : reprendre l'étape 2. |
| IONOS refuse un CNAME sur `@` | C'est normal et sans gravité : la racine prend un **A**, jamais un CNAME. Étape 4. |
| L'ancienne page IONOS s'affiche encore | Une *redirection de domaine* est active chez IONOS et passe avant le DNS : la supprimer. |
| Ça marche sur l'ordinateur, pas sur le téléphone | Simple retard : l'ancienne réponse est encore en mémoire quelque part. Attendre, ou essayer en navigation privée. |

IONOS propose aussi de confier le domaine aux serveurs de noms de Vercel. **À
éviter ici** : IONOS gère sans doute aussi vos courriels sur ce domaine, et
vous devriez les reconfigurer ailleurs. Les deux enregistrements ci-dessus
suffisent.

Pour un autre hébergeur de domaine (OVH, Gandi, Infomaniak), la marche est la
même : un **A** sur la racine, un **CNAME** `www` vers `cname.vercel-dns.com`.

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
  tablette reste connectée. Onglet **Encaisser**, il choisit **Numéro** ou
  **Nom**, tape les premiers caractères, et le client apparaît dans une liste
  de propositions. Un doigt dessus, le montant au pavé, **Encaisser**.
- **Le client** reçoit un lien personnel à la création de sa carte
  (`…/?c=xxxx`). À ajouter en favori ou sur l'écran d'accueil du téléphone.
  S'il le perd : bouton **J'ai déjà une carte**, téléphone + date de naissance.

Imprimer un petit carton au comptoir avec le QR code de l'adresse du site et la
mention « Créez votre carte en 30 secondes » : n'importe quel générateur de QR
code en ligne fait l'affaire à partir de l'adresse du site.

---

## 5 bis. Le logo

**Le logo de la Boucherie Vatuone est inscrit dans l'application** : dans le
bandeau de toutes les pages, à côté du nom sur chaque carte de fidélité, et en
filigrane sur la carte. Il n'y a rien à faire pour l'obtenir.

Sur les cartes, il n'est pas posé mais **découpé au pochoir** : c'est sa
silhouette qui est remplie de l'encre du style choisi — blanche sur la carte
rouge, brune sur le papier kraft, claire sur l'ardoise. Un logo rouge posé tel
quel sur une carte rouge ne se verrait pas ; découpé, il a toujours le bon
contraste. Dans le bandeau, en revanche, il garde ses couleurs d'origine.

Pour une autre boutique — ou pour remplacer ce logo par un autre fichier —
**Réglages → Logo → *Le logo de la boutique*.** Choisissez le fichier, il
apparaît aussitôt. Puis **Enregistrer les réglages** en bas du panneau — tant
que ce n'est pas fait, il n'est posé que sur cet appareil.

Une fois enregistré, il remplace le logo d'origine dans le bandeau, sur toutes
les pages, pour le boucher **comme pour les clients**, et il vient sur les
cartes de fidélité — celui-là posé sur une petite plaque, comme sur un
emballage, puisqu'on ne connaît pas ses couleurs.

Ce que l'application fait du fichier, et pourquoi :

- **Elle retire la marge vide avant de réduire.** Un logo d'imprimeur arrive
  presque toujours seul au milieu d'une page blanche : le fichier fourni pour
  cette boutique était une page de 1414 × 2000 pixels dont le dessin
  n'occupait que 9 %. Réduire d'abord aurait jeté la finesse du dessin pour ne
  garder que du vide — c'est ce qui se passait, et le logo sortait à 87 pixels
  de large. L'application cherche donc les bords du dessin **à pleine
  résolution**, recadre dessus en gardant 2 % de marge, et ne réduit
  qu'ensuite. Le nom du fichier affiché indique « marge retirée » quand c'est
  le cas, avec la taille obtenue.
- **Elle le redessine en PNG**, au plus 384 pixels de côté, ce qui suffit au
  plus grand usage (le filigrane de la carte sur un téléphone très fin). Une
  image plus petite que cela n'est jamais agrandie : on n'invente pas du
  détail. Sans cette réduction, chaque ouverture du site traînerait le poids du
  fichier d'origine.
- **Elle ne garde jamais le fichier tel quel.** Un SVG n'est pas une image,
  c'est du code, et ce code finirait dans la page. Redessiné, il n'en reste
  qu'une image : ce qu'un SVG pourrait contenir de malveillant ne survit pas
  au passage.
- Le fichier d'origine est refusé au-delà de 6 Mo, et le résultat au-delà de
  130 Ko. Dans ce cas, réduisez-le avant de le reprendre.

**Si votre logo est dessiné en blanc** — c'est fréquent, les logos sont
souvent faits pour une devanture ou un fond sombre — il devient invisible sur
le fond blanc de l'application. Cochez **« Mon logo est dessiné en blanc ou en
couleurs claires »** : l'application lui pose une plaque foncée dessous,
partout. Les deux aperçus juste au-dessus de la case, l'un sur fond clair et
l'autre sur fond sombre, montrent tout de suite ce qu'il en est.

**Pour retirer le logo déposé** : bouton *Retirer le logo*, puis
**Enregistrer**. Tout revient au logo inscrit dans l'application.

> Une note pour la revente : le logo d'origine est celui de la Boucherie
> Vatuone. Une autre boutique qui reprendrait l'application le verrait jusqu'à
> ce qu'elle dépose le sien — ce qui prend un appui. Pour livrer un modèle
> neutre, remplacez `assets/logo/vatuone.png` et la constante `LOGO_DEFAUT`
> dans `index.html`.

## 5 ter. Fixer le barème et les récompenses

Espace boucher → **Réglages**. Deux encadrés, l'un sous l'autre.

**Barème** — combien de points le client gagne.

| Champ | Ce qu'il fait |
| --- | --- |
| Points par euro dépensé | 1 = un point par euro. On peut mettre 1,5 ou 0,5. |
| Points de bienvenue | crédités à la création de la carte |
| Cadeau anniversaire | crédités une fois par an, le jour dit |
| Parrain / Filleul | crédités aux deux quand un parrainage aboutit |

**Récompenses** — ce que le client obtient, et à quel prix.

Chaque ligne est un palier : un nombre de points, puis ce que le client gagne.
**Mettez le nombre que vous voulez** : 250, 500, 1 000, 1 500 — n'importe quel
nombre entier à partir de 1. Le bouton **Ajouter** crée une ligne de plus, la
croix rouge en supprime une. **Enregistrer le barème** pour valider.

Les paliers se rangent tout seuls du moins cher au plus cher, et s'appliquent
**immédiatement sur toutes les cartes déjà créées** — les points déjà acquis
ne bougent pas, c'est seulement le prix des récompenses qui change.

Un ordre de grandeur pour s'y retrouver : à 1 point par euro, un palier à 500
points, c'est 500 € d'achats. Pour une boucherie où le panier tourne autour de
25 €, cela fait une vingtaine de passages — soit à peu près cinq mois pour un
client hebdomadaire. À vous de placer le curseur là où la récompense reste
atteignable.

---

## 6. Trouver le bon client

Au comptoir, la file attend : chercher un client ne doit pas prendre plus de
deux secondes. L'onglet **Encaisser** offre trois voies, dans cet ordre de
rapidité.

**Le scanner** — le client montre le code de sa carte, la caméra le lit, la
fiche s'ouvre. C'est le plus rapide quand le client a son téléphone en main
(voir « Le scanner », plus bas).

**Par numéro** — le choix par défaut. Le téléphone ouvre son **clavier
chiffres**. Dès le premier chiffre, les cartes qui commencent par ce chiffre
sont proposées ; à partir de quatre chiffres, les téléphones qui les
contiennent aussi. Utile quand le client dit « c'est le 1006 » ou donne la fin
de son numéro de portable.

**Par nom** — un appui sur **Nom** fait basculer le champ en **clavier
lettres**. À partir de deux lettres, les noms correspondants s'affichent, la
partie tapée surlignée. Le prénom et le nom de famille comptent autant l'un que
l'autre : « duclos » trouve Antoine Duclos. Les accents n'ont pas à être
tapés — « therese » trouve Thérèse Aubry.

Chaque proposition porte le **nom**, le **numéro de carte**, le **téléphone**
et les **points** : de quoi lever un doute entre deux homonymes sans ouvrir la
fiche. Six propositions au plus, sinon la liste cacherait le clavier ; s'il y
en a davantage, l'application le dit et invite à préciser.

Au clavier, la **flèche bas** descend dans les propositions et **Entrée**
choisit. Sans toucher aux flèches, **Entrée** dans le champ prend la première
proposition affichée — celle que le boucher a sous les yeux.

Côté client, la page « J'ai déjà une carte » ne propose **aucun nom** : ce
serait donner la liste des clients de la boutique au premier venu. Les
propositions n'existent que derrière le mot de passe du boucher.

## 7. Encaisser

L'écran d'encaissement ressemble à un terminal de paiement, et pas par hasard :
au comptoir, avec la file qui attend et les mains occupées, il ne faut rien
avoir à chercher. Une fois le client trouvé, la recherche s'efface et il ne
reste que trois choses.

**Le montant, au pavé.** Les chiffres entrent **par la droite, en centimes**,
comme sur un terminal bancaire : `4` `2` `5` `0` donne `42,50 €`. Pas de
virgule à trouver. `C` remet à zéro, `⌫` corrige le dernier chiffre. Sur un
ordinateur ou une tablette à clavier, les touches du clavier font la même
chose, et **Retour arrière** corrige.

Au-dessus du pavé, le montant en grand et, juste dessous, **les points que le
client va gagner** — mis à jour à chaque chiffre. Le boucher voit ce qu'il
donne avant de valider, et le client aussi s'il regarde l'écran.

**La raison de la venue** (facultative) — c'est ce qui a remplacé la liste des
morceaux achetés. Six réponses, un seul appui :

| | |
|---|---|
| **Habitué** | il serait venu de toute façon |
| **A reçu le SMS** | c'est le message qui l'a fait venir |
| **Nouveau client** | première fois |
| **Bouche à oreille** | on lui en a parlé |
| **Passait devant** | la vitrine a fait le travail |
| **Pour une récompense** | il vient chercher ce qu'il a gagné |

Ce n'est pas de la statistique pour la statistique. C'est la seule façon de
répondre à la question qui compte le jour où l'on paie des SMS : **est-ce que
ça fait revenir quelqu'un ?** Le tableau de bord affiche le compte des trois
derniers mois sous « Pourquoi ils viennent », et la colonne se retrouve dans
l'export des achats. Au bout de quelques semaines, le boucher sait si ses
envois lui rapportent plus qu'ils ne lui coûtent.

Rien n'oblige à répondre : sans appui, l'achat est enregistré comme « Achat en
boutique » et le reste fonctionne à l'identique.

**Le bouton**, enfin, reste accroché au bas de l'écran quel que soit le
défilement, et porte le montant : *Encaisser 42,50 €*. Il est fermé tant
qu'aucun montant n'est tapé — impossible de valider un achat à zéro. Une fois
validé, la caisse se vide d'elle-même et se remet en recherche pour le client
suivant : le même montant ne peut pas partir deux fois.

Les bandeaux qui comptent restent au-dessus : l'anniversaire du jour, et la
récompense disponible avec son bouton **Utiliser**.

## 8. Le scanner

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

## 8 bis. Gagner des points sans acheter

**Réglages → Points en plus.** Trois actions, chacune avec son lien et son
barème : abonnement Instagram, abonnement Facebook, avis Google.

**Les trois liens de la boutique sont déjà remplis** à la première ouverture ;
il ne reste qu'à vérifier les points et à appuyer sur **Enregistrer**. Rien
n'est proposé aux clients tant que ce n'est pas enregistré : les valeurs
proposées remplissent le formulaire, elles n'autorisent rien. C'est
volontaire — la base lit le barème dans la fiche boutique, et une action que
la page afficherait sans que la fiche la porte serait refusée au moment de
créditer.

**Pour une autre boutique : collez le lien, mettez un nombre de points,
enregistrez.** C'est tout : il n'y a rien à activer.

> **Le lien d'avis Google demande une précaution.** Copié depuis un compte
> connecté, Google donne une adresse de la forme
> `accounts.google.com/v3/signin/…?continue=…&dsh=…` : c'est une page de
> connexion, et le `dsh` est un jeton pris dans *votre* navigateur. Publiée
> telle quelle, elle enverrait chaque client se connecter d'abord. La bonne
> adresse est celle qu'elle contient :
> `https://search.google.com/local/writereview?placeid=VOTRE_PLACE_ID`. Une action qui a un lien et des points est proposée,
une action sans lien ne l'est pas. Chaque ligne affiche son état — *Proposée
aux clients*, ou ce qu'il lui manque — et le panneau récapitule en une phrase
ce que vos clients voient réellement sur leur carte.

Sur sa carte, le client voit une section *Gagner des points en plus*. Un appui
ouvre votre page et crédite les points. Chaque action ne compte **qu'une
fois** : ensuite elle reste affichée, marquée « déjà fait » et datée, avec un
simple lien pour y retourner.

Deux points à savoir avant de fixer le barème :

- **Les points sont accordés sur parole.** L'application ouvre le lien et
  crédite, sans pouvoir vérifier que le client s'est vraiment abonné — aucun
  site ne donne cette information à un tiers. Chaque geste laisse une trace
  dans l'historique de la fiche et dans le journal de la boutique : si vous
  constatez un abus, retirez les points depuis la fiche du client.
- **Ce qui, en revanche, n'est pas négociable** : le nombre de points est lu
  dans la fiche boutique par la base elle-même, jamais reçu du navigateur — un
  client qui trafique la page ne peut pas s'accorder mille points. Et la règle
  « une seule fois » est un index d'unicité en base, pas une vérification dans
  la page. Les deux sont vérifiés par des essais qui tentent la fraude pour de
  bon.

Pour le lien d'avis Google : sur votre fiche d'établissement, *Demander des
avis* donne une adresse courte du type `g.page/r/…/review` qui ouvre
directement la fenêtre de notation.

## 9. La signature du client

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

## 10. Écrire à une partie des clients

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

## 11. Envoyer vraiment, par Brevo (facultatif)

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

### « Et si on mettait la clé du côté boucher, il est protégé par mot de passe ? »

Non, et c'est le piège le plus naturel. Le mot de passe cache un **écran**, pas
un **fichier**.

Le côté client et le côté boucher sont **le même fichier**, à la même adresse.
Quand une cliente ouvre sa carte, son navigateur télécharge l'application
entière — y compris le code de l'espace boucher. Le mot de passe décide
seulement de ce que ce code accepte d'**afficher**. Il intervient bien après
que tout est arrivé chez elle.

Vérifié en fabriquant exactement cette version — clé posée dans le code, du
côté boucher — puis en l'attaquant depuis la carte d'une cliente qui n'a pas le
mot de passe. L'espace boucher lui est bien refusé. La clé, elle, sort de trois
façons, en quelques secondes et sans compétence particulière :

1. menu **Afficher le code source de la page** (Ctrl+U), puis chercher `xkeysib` ;
2. la console du navigateur, en lisant le script comme du texte ;
3. `curl https://…/index.html | grep xkeysib`, sans même ouvrir de navigateur.

Une clé posée dans une page web est une clé publiée. Celle-ci donne le droit
d'envoyer des SMS aux frais de la boutique : le crédit peut être vidé par
n'importe qui.

C'est pour cette seule raison que l'envoi passe par une fonction serveur.
Ce n'est pas de la prudence excessive, c'est la seule façon.

### Faut-il transférer les clients dans Brevo ? Non.

C'est la question qui vient d'abord, et la réponse est *non*. La fonction
d'envoi lit les fiches **dans votre base Supabase** au moment de l'envoi et
donne à Brevo, pour ce message-là, les seules adresses et numéros concernés.
Brevo sert de facteur, pas d'annuaire. Rien n'est à téléverser, rien n'est à
tenir à jour en double, et un client effacé de la carte de fidélité disparaît
du même coup des envois.

Il reste **un** cas où l'on exporte : si vous voulez faire vos campagnes depuis
l'interface de Brevo, avec ses modèles et ses statistiques. Dans **Clients**,
cochez qui vous voulez et prenez **Exporter pour Brevo**. Le fichier est au
format d'import de Brevo (colonnes `EMAIL`, `SMS`, `PRENOM`, `NOM`,
`NUM_CARTE`, `POINTS`, `ANNIVERSAIRE`), les téléphones y sont déjà convertis au
format international (`33…`) que Brevo exige, et **seuls les clients qui ont
accepté les offres y figurent** — l'application vous dit combien elle a écartés.

Sachez ce que vous perdez en faisant cela : une fois les contacts dans Brevo,
c'est Brevo qui décide qui reçoit quoi. Le filtre du consentement ne se refait
plus, le lien de désinscription vers la carte n'est plus ajouté, et un client
qui décoche la case chez vous **reste dans la liste Brevo**. À vous de l'y
retirer. C'est pour cela que l'envoi depuis le site est la voie recommandée.

### Ce qu'il faut faire, une fois

**Sans rien installer**, depuis le navigateur — c'est la voie à conseiller au
boucher, elle ne demande aucun terminal :

**1. Créer un compte Brevo** sur [brevo.com](https://www.brevo.com), puis
Paramètres → **SMTP & API** → onglet **Clés d'API** → *Générer une nouvelle
clé*. Elle commence par `xkeysib-`. Copiez-la, elle ne sera plus jamais
affichée.

**2. Vérifier l'expéditeur** dans Brevo (Expéditeurs, domaines & adresses IP) :
l'adresse d'envoi des courriels, et un **nom d'expéditeur** de 11 caractères
maximum pour les SMS — obligatoire en France.

**3. Poser la clé dans Supabase** : [supabase.com](https://supabase.com) →
votre projet → **Edge Functions** → **Secrets** → *Add new secret*.
Nom : `BREVO_KEY`. Valeur : la clé. **Save**. Elle est désormais rangée du côté
serveur ; ni la page, ni le navigateur, ni personne d'autre n'y a accès.

**4. Publier la fonction** : toujours dans **Edge Functions**, *Deploy a new
function* → *Via Editor*. Nom de la fonction : `envoyer`, exactement.
Effacez l'exemple, collez tout le contenu du fichier
`supabase/functions/envoyer/index.ts` de ce dépôt, puis **Deploy**.

**5. Dans l'application**, Réglages → **Envoi automatique** : l'adresse
d'expédition, le nom affiché, le nom court des SMS et l'adresse du site (elle
sert au lien de désinscription). Puis **Vérifier la connexion** : l'application
dit si tout est en place, ou nomme ce qui manque.

Ces cinq étapes ne se font qu'une fois. Ensuite, dans la fenêtre d'écriture,
les boutons **Envoyer les courriels** et **Envoyer les SMS** partent d'ici, au
nom de la boutique. Tant que ce n'est pas fait, la fenêtre l'annonce et propose
un bouton **Activer** qui mène droit au bon réglage.

**Avec un terminal** — une seule commande, depuis le dossier du projet :

```bash
sh scripts/brevo.sh
```

Elle installe tout : connexion, rattachement du projet, saisie de la clé (à
l'aveugle, elle n'est ni affichée, ni écrite sur le disque, ni conservée dans
l'historique du terminal), et publication de la fonction.

**Ou étape par étape en ligne de commande**, si vous préférez tout voir passer
(les étapes 1 et 2 ci-dessus — compte Brevo et expéditeur vérifié — restent à
faire d'abord) :

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

**6. Dans l'application**, Réglages → **Envoi automatique**, comme à l'étape 5
plus haut.

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

## 12. Se mettre en règle (RGPD)

Une fois le site en ligne, ouvrir **Réglages → Données personnelles** et
compléter raison sociale, adresse, SIRET, directeur de la publication et
contact : ces informations alimentent les mentions légales et la politique de
confidentialité que les clients peuvent consulter. Tant qu'elles sont vides,
les pages affichent « à compléter », ce qui n'est pas conforme.

Le reste — registre des traitements, contrats de sous-traitance, affichette au
comptoir, conduite à tenir en cas de fuite — est détaillé dans
[RGPD.md](RGPD.md), avec un registre prérempli à imprimer.

### Le numéro d'un client qui refuse les offres

À l'inscription, le client peut cocher ou non « j'accepte de recevoir les
offres et les nouveautés ». **S'il ne coche pas, son numéro de téléphone
n'apparaît nulle part côté boucher** : ni dans le fichier clients, ni sur sa
fiche, ni dans les anniversaires, ni à la caisse, ni dans les exports CSV, ni
dans l'envoi de SMS. À la place s'affiche « numéro masqué ».

Ce qui continue de marcher :

- **La carte fonctionne normalement.** Points, récompenses, encaissement,
  anniversaire : rien ne change.
- **La caisse trouve toujours le client par son numéro.** Le client annonce
  « 06 12 48 03 77 », le boucher le tape, la bonne fiche s'ouvre — sans que le
  numéro soit réaffiché.
- **Le client retrouve sa carte** avec téléphone + date de naissance, comme
  avant.
- **Le client voit son propre numéro** sur sa carte, et peut le corriger.
- **Le boucher peut corriger la fiche** : le champ Téléphone est vide, il en
  saisit un nouveau s'il le faut, et le laisser vide conserve l'ancien.

Ce qui ne marche plus, et c'est voulu :

- **Le boucher ne peut plus appeler ni envoyer de SMS à ce client** — même
  pour un message de service comme « votre commande est prête ». S'il a une
  adresse e-mail, ce canal reste ouvert ; sinon, le client n'est joignable
  qu'au comptoir.

Le client peut changer d'avis à tout moment depuis sa carte : la case
recochée, le numéro réapparaît immédiatement côté boucher.

> **Une limite à connaître.** C'est une règle que l'application applique, pas
> un coffre-fort. Le numéro reste enregistré dans la base — il le faut, c'est
> la clé de la carte. Qui ouvre le tableau de bord Supabase voit la colonne.
> La boutique reste propriétaire et responsable de sa base ; le masquage
> protège du geste ordinaire, pas de la volonté d'aller voir.

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
