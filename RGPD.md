# RGPD — ce qui est fait, ce qui reste à faire

Le boucher qui exploite ce programme est **responsable de traitement** : c'est
lui qui répond des données de ses clients, pas l'hébergeur ni l'auteur du
logiciel. Ce document sépare ce que l'application assure déjà de ce qui relève
de lui.

> Ce document s'appuie sur les recommandations de la CNIL relatives aux
> programmes de fidélité. Il ne remplace pas l'avis d'un juriste, en particulier
> si le logiciel est revendu à plusieurs commerçants.

---

## 1. Ce que l'application fait déjà

| Exigence | Comment c'est assuré |
|---|---|
| **Minimisation** (art. 5.1.c) | Seuls le **jour et le mois** d'anniversaire sont demandés — jamais l'année. L'e-mail est facultatif. Aucune donnée bancaire. Aucune donnée sensible. |
| **Base légale** (art. 6) | La carte relève de l'exécution du programme ; les offres commerciales relèvent du **consentement**, recueilli par une case **séparée et non pré-cochée**. |
| **Preuve du consentement** (art. 7.1) | Date, heure et version de la notice sont enregistrées à l'inscription. L'acceptation des offres est horodatée séparément. |
| **Information** (art. 13) | Politique de confidentialité et mentions légales accessibles depuis le bas de chaque page et depuis le formulaire d'inscription, rédigées à partir des informations de la boutique. |
| **Accès et portabilité** (art. 15 et 20) | Le client télécharge l'intégralité de ses données en JSON depuis sa carte, en un clic. |
| **Rectification** (art. 16) | Le client corrige lui-même nom, téléphone, e-mail et anniversaire. |
| **Effacement** (art. 17) | Le client supprime sa carte lui-même. Fiche et historique disparaissent ; la boutique n'en garde qu'une ligne de journal sans nom. |
| **Opposition** (art. 21) | Case « je souhaite recevoir les offres » activable et désactivable à tout moment depuis la carte, sans perte de points. |
| **Conservation limitée** (art. 5.1.e) | Durée réglable, **trois ans par défaut** après le dernier passage. Les fiches dépassées sont signalées dans les réglages et supprimables en un clic ; purge automatique possible via `pg_cron`. |
| **Sécurité** (art. 32) | HTTPS ; aucune table accessible sans être connecté ; le personnel autorisé est une liste explicite ; les points sont calculés par la base, jamais par le navigateur ; en-têtes de sécurité et politique de contenu restreinte ; journal des opérations. |
| **Traceurs** (ePrivacy) | Aucun cookie publicitaire, aucune mesure d'audience. Le stockage local sert uniquement à retrouver sa carte : strictement nécessaire, donc **aucun bandeau de consentement n'est requis**. |

## 2. Ce qui reste à la charge de la boutique

Personne ne peut le faire à sa place.

1. **Compléter l'identité légale** — Espace boucher → Réglages → Données
   personnelles : raison sociale, adresse, SIRET, directeur de la publication,
   contact. Tant que c'est vide, les pages affichent « à compléter », ce qui
   n'est pas conforme.
2. **Vérifier que la base est en Europe** — Supabase → Settings → General →
   *Region*. Elle doit être européenne (Paris, Francfort, Irlande…). Si le
   projet a été créé aux États-Unis, en recréer un en Europe et y rejouer
   `supabase/schema.sql` : cela évite toute question de transfert hors UE.
3. **Accepter les contrats de sous-traitance** (art. 28) — Supabase et Vercel
   proposent chacun un DPA à accepter depuis le tableau de bord. Sans cela, le
   recours à ces prestataires n'est pas couvert.
4. **Tenir le registre des traitements** (art. 30) — le modèle prérempli est au
   point 3 ci-dessous. À imprimer, compléter, dater, et présenter en cas de
   contrôle.
5. **Informer aussi en boutique** — le client qui donne son numéro au comptoir
   doit être informé à ce moment-là. Affichette type au point 4.
6. **Savoir réagir à une fuite** (art. 33) — en cas d'accès non autorisé aux
   données : notifier la CNIL sous **72 heures** via cnil.fr, et prévenir les
   clients si le risque est élevé. Consigner l'incident.
7. **Ne pas ajouter de mesure d'audience** — activer Vercel Analytics, Google
   Analytics ou un pixel publicitaire ferait retomber le site sous l'obligation
   de bandeau de consentement, et changerait la présente analyse.
   Pour la même raison la police de caractères est hébergée avec le site et non
   chargée depuis Google Fonts : appeler le serveur de Google transmettrait
   l'adresse IP de chaque visiteur à un tiers, hors Union européenne et sans
   son accord — ce que la CNIL et les tribunaux ont déjà sanctionné. Ne pas
   réintroduire de lien vers `fonts.googleapis.com`.
8. **Signer le contrat de sous-traitance de Brevo** — si vous activez l'envoi
   automatique. Brevo met à disposition un accord de traitement des données
   (DPA) dans les paramètres du compte : il faut l'accepter, et le conserver.
   Sans envoi automatique, ce point ne vous concerne pas.
9. **Répondre aux demandes** — le client a un mois pour obtenir une réponse.
   L'application couvre déjà les cas courants en libre-service ; pour le reste,
   l'export CSV et la fiche client permettent de répondre.

## 3. Registre des activités de traitement (modèle prérempli)

À compléter aux endroits entre crochets.

| Rubrique | Contenu |
|---|---|
| **Nom du traitement** | Programme de fidélité clients |
| **Responsable de traitement** | [Raison sociale], [adresse], [SIRET] — représenté par [nom du gérant] |
| **Contact** | [e-mail] — [téléphone] |
| **Finalités** | Gestion des cartes de fidélité : cumul de points, récompenses, cadeau d'anniversaire, parrainage, historique d'achats. Information des clients (commande prête, horaires). Envoi d'offres commerciales aux seuls clients l'ayant accepté. |
| **Base légale** | Exécution du programme de fidélité souscrit par le client. Consentement pour les offres commerciales. Obligation du responsable de démontrer le consentement (art. 7.1) pour la signature et l'horodatage. |
| **Personnes concernées** | Clients de la boutique ayant adhéré au programme |
| **Catégories de données** | Identité : nom et prénom. Coordonnées : téléphone, e-mail (facultatif). Vie personnelle : jour et mois de naissance. Données d'achat : date, montant, nature des achats, points, récompenses. Parrainage : lien entre clients. Preuve du consentement : case cochée, horodatage, signature manuscrite. |
| **Données sensibles** | Aucune. La signature est conservée comme simple preuve d'accord (art. 7.1) : elle n'est ni analysée, ni comparée, ni utilisée pour identifier qui que ce soit. Elle ne constitue donc pas une donnée biométrique au sens de l'article 9. |
| **Destinataires** | Le gérant et le personnel habilité de la boutique. Pour les envois groupés : soit l'opérateur téléphonique ou le fournisseur de messagerie du gérant, qui achemine le message depuis son propre téléphone ; soit Brevo si l'envoi automatique est activé, qui reçoit alors le nom et l'adresse ou le téléphone des seuls destinataires de l'envoi. |
| **Sous-traitants** | Supabase (hébergement de la base, région [région]) ; Vercel (hébergement de la page) ; Brevo (acheminement des courriels et SMS, société française, données en Union européenne) — seulement si l'envoi automatique est activé |
| **Transferts hors UE** | Aucun — base hébergée en Union européenne |
| **Durée de conservation** | 3 ans à compter du dernier passage en boutique, puis suppression de la fiche et de son historique |
| **Mesures de sécurité** | Accès par compte nominatif et mot de passe ; chiffrement des échanges (HTTPS) ; tables inaccessibles sans authentification ; liste explicite du personnel autorisé ; calcul des points côté serveur ; journal des opérations ; sauvegardes |
| **Date de création du registre** | [date] |

## 4. Affichette pour le comptoir

> **Carte de fidélité — vos données**
>
> Nous enregistrons votre nom, votre téléphone, le jour et le mois de votre
> anniversaire, ainsi que vos achats, dans le seul but de gérer votre carte de
> fidélité. L'e-mail est facultatif. Nous ne demandons jamais votre année de
> naissance et ne transmettons vos données à personne.
>
> Vous pouvez consulter, corriger, récupérer ou supprimer vos données à tout
> moment depuis votre carte, rubrique « Mes données ». Vos données sont
> effacées après 3 ans sans passage.
>
> Questions : [e-mail] — [téléphone]. Réclamation : cnil.fr

## 5. Vérifier que l'installation tient

Espace boucher → Réglages → Base en ligne → **Vérifier l'installation**.
Les quatre contrôles doivent être verts : c'est ce qui atteste que le fichier
clients n'est pas accessible publiquement.

À refaire après toute modification du schéma ou changement de projet Supabase.
