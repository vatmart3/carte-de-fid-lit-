# Mettre la carte de fidélité en ligne

Objectif : une adresse web unique, le boucher encaisse depuis sa tablette,
chaque client consulte sa carte depuis son propre téléphone.

Compter **une heure** la première fois. Coût : 0 € par mois (offres gratuites
Supabase + Netlify), 10 à 15 € par an si vous voulez un nom de domaine à vous.

---

## 1. Créer la base — Supabase

1. Sur https://supabase.com, créer un projet (région **Europe (Paris)** ou
   **Frankfurt** : les données restent en Europe, c'est ce qu'attend le RGPD).
   Noter le mot de passe de la base, il ne sera plus affiché.
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

## 3. Publier le site — Netlify

1. Sur https://app.netlify.com → **Add new site** → **Deploy manually**.
2. Glisser le fichier `index.html` (seul) dans la zone de dépôt.
3. Le site est en ligne sur une adresse du type
   `https://nom-invente-123.netlify.app`. La renommer dans
   **Site configuration → Change site name**.

Alternatives équivalentes : Vercel, Cloudflare Pages, GitHub Pages, ou
l'hébergement mutualisé d'un hébergeur français — c'est un fichier statique,
n'importe quel hébergement fait l'affaire.

### Nom de domaine (facultatif)

Acheter `fidelite-boucherie-xxx.fr` (OVH, Gandi, Infomaniak : ~12 €/an), puis
Netlify → **Domain management → Add a domain**. Le certificat HTTPS est
automatique.

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
