#!/bin/sh
# Installe l'envoi Brevo : la clé va dans les secrets Supabase, jamais dans la
# page. À lancer une fois, depuis le dossier du projet.
#
#   sh scripts/brevo.sh
#
# La clé n'est ni affichée, ni écrite sur le disque, ni gardée dans
# l'historique du terminal : elle est saisie à l'aveugle et transmise
# directement à Supabase.

set -e
PROJET="edgivtkpqyziucjyzffs"

echo
echo "  Installation de l'envoi Brevo"
echo "  ─────────────────────────────"
echo

if ! command -v supabase >/dev/null 2>&1; then
  echo "  L'outil Supabase n'est pas installé. Une seule commande :"
  echo
  echo "      npm install -g supabase"
  echo
  echo "  (si npm n'existe pas non plus, installez Node.js depuis nodejs.org)"
  exit 1
fi

echo "  1/4  Connexion à Supabase"
supabase projects list >/dev/null 2>&1 || supabase login

echo "  2/4  Rattachement au projet $PROJET"
supabase link --project-ref "$PROJET" >/dev/null 2>&1 || supabase link --project-ref "$PROJET"

echo "  3/4  Clé Brevo"
echo
echo "       Elle se trouve dans Brevo → Paramètres → SMTP & API → Clés d'API."
echo "       Elle commence par xkeysib-. Rien ne s'affichera pendant la saisie."
echo
printf "       Collez la clé puis Entrée : "
stty -echo 2>/dev/null || true
read CLE
stty echo 2>/dev/null || true
echo
echo

case "$CLE" in
  xkeysib-*) ;;
  "") echo "  Aucune clé saisie. Rien n'a été fait."; exit 1 ;;
  *) echo "  Cette clé ne commence pas par xkeysib- : ce n'est probablement pas"
     echo "  une clé d'API Brevo. Rien n'a été fait."; exit 1 ;;
esac

supabase secrets set "BREVO_KEY=$CLE" >/dev/null
CLE=""
echo "       Clé rangée dans les secrets Supabase."

echo "  4/4  Publication de la fonction d'envoi"
supabase functions deploy envoyer

echo
echo "  ✓ Terminé."
echo
echo "  Il reste à ouvrir l'application → Réglages → Envoi automatique,"
echo "  à renseigner l'adresse d'expédition et le nom court des SMS,"
echo "  puis à appuyer sur « Vérifier la connexion »."
echo
