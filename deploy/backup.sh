#!/usr/bin/env bash
#
# Sauvegarde du serveur local de l'American Shelf de Tiassalé.
#
# Recopie le fonds, les abonnés, les prêts et les couvertures sur la clé USB
# laissée branchée au poste, en gardant les trente derniers jours. Lancé
# chaque soir avant l'extinction (README.md, étape 9), ou à la main :
#
#   ./backup.sh                       vers /media/shelf-backup
#   ./backup.sh /un/autre/dossier     ailleurs
#
# Demande sqlite3 et rsync sur le poste :
#   sudo apt install sqlite3 rsync

set -euo pipefail

SOURCE="${SHELF_STORAGE:-/srv/shelf/storage}"
DESTINATION="${1:-/media/shelf-backup}"
DAYS_KEPT=30

TARGET="$DESTINATION/$(date +%Y-%m-%d)"

if [ ! -d "$SOURCE" ]; then
  echo "Données introuvables : $SOURCE" >&2
  echo "Le serveur a-t-il déjà démarré au moins une fois ?" >&2
  exit 1
fi

if [ ! -d "$DESTINATION" ]; then
  echo "Destination introuvable : $DESTINATION" >&2
  echo "La clé USB est-elle branchée et montée ?" >&2
  exit 1
fi

mkdir -p "$TARGET"

# .backup et non cp : le comptoir peut être en train d'enregistrer un prêt
# pendant la copie, et une copie brute donnerait un fichier tronqué qu'on ne
# découvrirait que le jour où il faut s'en servir.
#
# Seule production.sqlite3 est reprise. Les bases cache, queue et cable sont
# techniques : Rails les recrée vides au démarrage suivant.
sqlite3 "$SOURCE/production.sqlite3" ".backup '$TARGET/production.sqlite3'"

# Une sauvegarde qu'on ne relit jamais n'est pas une sauvegarde. On vérifie
# maintenant, pendant qu'il reste une copie saine sur le disque du poste.
verdict="$(sqlite3 "$TARGET/production.sqlite3" 'pragma integrity_check;')"
if [ "$verdict" != "ok" ]; then
  echo "Sauvegarde illisible, elle ne servirait à rien : $verdict" >&2
  exit 1
fi

# Les couvertures d'ouvrages photographiées au comptoir.
rsync -a --exclude='*.sqlite3*' "$SOURCE/" "$TARGET/fichiers/"

# Rotation. Trente jours suffisent : une erreur de saisie se remarque en
# quelques jours, et la clé ne doit pas se remplir en silence.
find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d -name '20*' \
  -mtime +"$DAYS_KEPT" -exec rm -rf {} +

taille="$(du -sh "$TARGET" | cut -f1)"
jours="$(find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d -name '20*' | wc -l)"
echo "Sauvegarde faite : $TARGET ($taille). $jours jours conservés."
