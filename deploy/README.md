# Serveur local de l'American Shelf de Tiassalé

Comment installer l'application sur un poste de l'Espace pour qu'elle
fonctionne **sans internet**.

## Le principe

Un poste de la salle informatique devient le serveur. Il garde toutes les
données sur son disque. Les téléphones du comptoir l'atteignent par le Wi-Fi
de la bibliothèque, en ouvrant une page web. Rien ne sort du bâtiment.

| Élément | Rôle |
|---|---|
| Une unité centrale dédiée | Le serveur. Personne d'autre ne s'en sert. |
| Le routeur / la box | Le réseau local seulement. **Aucun abonnement internet n'est nécessaire.** |
| Les téléphones, les postes de la salle | Des clients. Ils ouvrent une adresse. |

Internet ne sert qu'à trois choses, toutes facultatives : publier le catalogue
vers le futur site public, sortir une sauvegarde du bâtiment, installer une
mise à jour. **Aucune n'est nécessaire pour prêter un livre.**

## Ce qu'il faut avoir sous la main

- L'unité centrale choisie, avec un écran et un clavier **le temps de
  l'installation seulement**. Ensuite elle tourne aveugle.
- Une clé USB de 8 Go pour installer Ubuntu, une autre qui restera branchée
  en permanence pour les sauvegardes.
- L'accès au routeur de l'Espace (adresse et mot de passe d'administration).
- Le fichier `config/master.key` du projet. **Il n'est pas dans le dépôt
  Git** — il se copie à la main, c'est lui qui déchiffre les identifiants.
- Une connexion internet **le jour de l'installation uniquement**, pour
  télécharger Ubuntu et Docker. Après, plus jamais.

## À vérifier avant de partir : les navigateurs du comptoir

C'est le point qui peut faire échouer toute l'installation, et il se
vérifie en trente secondes, depuis n'importe où.

Sur chaque téléphone et chaque poste qui servira au comptoir, ouvrir le
navigateur et regarder sa version (Chrome : menu ⋮ → Paramètres → À propos
de Chrome). Il faut au minimum :

| Navigateur | Version minimale | Sortie |
|---|---|---|
| Chrome / Edge | 111 | mars 2023 |
| Safari (iPhone) | 16.4 | mars 2023 |
| Firefox | 113 | mai 2023 |

En dessous, l'application affiche une page d'explication et rien d'autre :
la feuille de style et le JavaScript utilisent des fonctionnalités que ces
navigateurs ne connaissent pas, et la page s'afficherait nue ou sans menu.

**Pourquoi c'est bloquant ici et pas ailleurs :** une fois le serveur en
place, le Wi-Fi de l'Espace ne donne pas internet. Un navigateur trop
ancien ne pourra donc plus se mettre à jour sur place. Il faut le faire
**avant**, avec une connexion mobile, ou prévoir un autre appareil.

---

## Étape 1 — Installer Ubuntu Server

Télécharger Ubuntu Server LTS et le graver sur la clé USB avec Rufus ou
BalenaEtcher. Démarrer le poste dessus et suivre l'installation.

Trois choix à ne pas manquer pendant l'installation :

- **Ne pas installer d'environnement de bureau.** Ubuntu Server sans interface
  graphique consomme environ 500 Mo. Avec un bureau, on retomberait dans le
  problème qu'on cherche à éviter.
- **Cocher « Install OpenSSH server »** : ça permet de dépanner la machine
  depuis un autre poste, sans aller débrancher un écran.
- Retenir le nom d'utilisateur et le mot de passe créés.

> Cette étape efface tout ce qui se trouve sur le disque. À ne faire qu'après
> avoir vérifié qu'il n'y a rien à conserver dessus, et avec l'accord du
> responsable de l'Espace.

## Étape 2 — Réveiller l'horloge

Toute l'application repose sur des dates : échéance à quatorze jours,
expiration d'adhésion, calcul des retards. Sans internet, il n'y a pas de
synchronisation automatique, et sur une machine ancienne la pile de la carte
mère est souvent morte.

```bash
timedatectl                              # la date affichée est-elle la bonne ?
sudo timedatectl set-timezone UTC        # Abidjan est à UTC toute l'année
sudo timedatectl set-time "2026-08-29 09:30:00"   # si elle est fausse
```

Si la date est encore fausse après un redémarrage, la pile est à changer.
C'est une pile bouton à quelques centaines de francs, mais découvert trois
mois plus tard, ça fausse tous les retards.

## Étape 3 — Donner une adresse fixe au poste

Relever l'adresse actuelle :

```bash
ip -4 addr show | grep inet
```

Puis, dans l'interface du routeur, **réserver cette adresse** pour ce poste
(souvent « DHCP reservation » ou « bail statique »). Sans ça, le routeur peut
lui en attribuer une autre après une coupure, et le raccourci du comptoir ne
mènerait plus nulle part.

Retenir l'adresse choisie, par exemple `192.168.1.50`.

## Étape 4 — Installer Docker

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2 sqlite3 rsync git
sudo usermod -aG docker "$USER"
```

Se déconnecter puis se reconnecter pour que le groupe `docker` prenne effet.

> Il s'agit de **Docker Engine**, pas de Docker Desktop. Sur Linux, c'est de
> l'isolation de processus, pas une machine virtuelle : le coût en mémoire est
> de quelques dizaines de mégaoctets.

## Étape 5 — Déposer l'application

```bash
sudo mkdir -p /srv/shelf/storage
sudo chown -R "$USER:$USER" /srv/shelf

git clone <adresse-du-depot> /srv/shelf/app
cd /srv/shelf/app
```

Copier `config/master.key` depuis le poste de développement (clé USB ou `scp`),
puis en faire un fichier d'environnement pour Docker :

```bash
echo "RAILS_MASTER_KEY=$(cat config/master.key)" > deploy/.env
chmod 600 deploy/.env
```

Enfin, ouvrir `deploy/compose.yaml` et remplacer `APP_HOST` par l'adresse
retenue à l'étape 3.

## Étape 6 — Démarrer

```bash
cd /srv/shelf/app/deploy
docker compose up -d --build
```

La première construction télécharge Ruby et installe les bibliothèques :
comptez **quinze à trente minutes** sur une machine ancienne. C'est la seule
fois. Les démarrages suivants sont immédiats.

Vérifier :

```bash
docker compose logs -f      # Ctrl+C pour sortir
curl -I http://localhost/up # doit répondre 200
```

Depuis un téléphone connecté au Wi-Fi de l'Espace, ouvrir `http://192.168.1.50`.

## Étape 7 — Créer le premier compte

Il n'y a pas d'écran d'inscription dans l'application, et c'est voulu : un
espace bibliothécaire ne doit pas laisser un inconnu se créer un compte. Les
comptes se gèrent depuis le poste serveur.

```bash
docker compose exec app bin/rails "bibliothecaire:creer[bibliothecaire@shelf.ci,motdepasse]"
docker compose exec app bin/rails bibliothecaire:lister
```

Huit caractères minimum, la commande refuse en dessous.

La même commande **redonne un mot de passe** à un compte existant : si
l'adresse est déjà connue, elle remplace le mot de passe au lieu de créer un
compte. C'est elle que l'écran « mot de passe oublié » affiche au
bibliothécaire quand il se retrouve dehors, puisqu'aucun e-mail ne peut
partir d'ici.

> À savoir : cette commande ne ferme pas les sessions déjà ouvertes, alors que
> l'écran de réinitialisation par e-mail, lui, les ferme. Si le mot de passe
> est changé parce qu'un téléphone a été perdu, il faut aussi déconnecter
> l'appareil — c'est un écart à corriger dans `lib/tasks/librarian.rake`.

## Étape 8 — Charger le fonds

À faire **une seule fois**, sur une base vide :

```bash
docker compose exec app bin/rails db:seed
```

Les dix-neuf titres, les quatre-vingt-treize exemplaires, les catégories et
les cotes de rangement sont créés. Le fichier est idempotent : le relancer ne
crée pas de doublons.

## Étape 9 — Sauvegarde, allumage et extinction automatiques

C'est l'étape qui rend le montage défendable. Sans elle, toutes les données de
la bibliothèque tiennent sur un seul disque, dans un local avec des coupures
de courant.

**La clé USB de sauvegarde.** La brancher, repérer son nom avec `lsblk`, puis
la monter à demeure sur `/media/shelf-backup` (une ligne dans `/etc/fstab`,
avec l'UUID donné par `blkid`).

**Le service de sauvegarde**, dans `/etc/systemd/system/shelf-backup.service` :

```ini
[Unit]
Description=Sauvegarde de l'American Shelf

[Service]
Type=oneshot
ExecStart=/srv/shelf/app/deploy/backup.sh
User=<votre-utilisateur>
```

**Le déclencheur du soir**, dans `/etc/systemd/system/shelf-backup.timer` —
régler l'heure sur la fermeture de l'Espace :

```ini
[Unit]
Description=Sauvegarde chaque soir à la fermeture

[Timer]
OnCalendar=*-*-* 18:15:00
Persistent=true

[Install]
WantedBy=timers.target
```

Puis :

```bash
chmod +x /srv/shelf/app/deploy/backup.sh
sudo systemctl daemon-reload
sudo systemctl enable --now shelf-backup.timer
sudo systemctl start shelf-backup.service   # essai immédiat
```

**L'extinction du soir**, une demi-heure après la sauvegarde :

```bash
sudo systemctl edit --force --full shelf-shutdown.timer
```

Même forme que ci-dessus, avec `OnCalendar=*-*-* 18:45:00` et un service qui
lance `/sbin/shutdown -h now`.

**L'allumage du matin** ne se règle pas dans Ubuntu mais **dans le BIOS** du
poste : chercher `RTC Alarm Power On`, `Wake on RTC` ou `Power On by Alarm`, et
programmer 7 h 30. La plupart des unités centrales de bureau le proposent.
Si celle-ci ne l'a pas, il restera un bouton à presser le matin — c'est le
seul geste manuel de tout le montage.

---

## Au quotidien

| Situation | Geste |
|---|---|
| Le matin | Rien. Le poste s'allume et l'application démarre seule. |
| Le soir | Rien. Sauvegarde puis extinction automatiques. |
| L'écran ne s'affiche plus | Vérifier que le poste est allumé, puis `docker compose restart` |
| Voir ce qui se passe | `docker compose logs --tail 100` |
| Mot de passe oublié | `bin/rails "bibliothecaire:creer[adresse,nouveau-mot-de-passe]"` (étape 7) |
| Mettre à jour l'application | `git pull && docker compose up -d --build` |

**Restaurer après un incident** — sur le poste de secours, refaire les étapes
1 à 6, puis, avant le premier démarrage :

```bash
cp /media/shelf-backup/2026-08-28/production.sqlite3 /srv/shelf/storage/
rsync -a /media/shelf-backup/2026-08-28/fichiers/ /srv/shelf/storage/
```

## Ce qui n'est pas encore fait

- **Le second poste de secours.** Même installation, machine éteinte dans un
  placard. C'est la précaution qui compte le plus sur du matériel de
  récupération, et elle ne coûte qu'une unité centrale déjà disponible.
- **La copie hors du bâtiment.** La clé USB est dans la même pièce que le
  serveur : un vol ou un dégât des eaux emporterait les deux. Il faudra
  envoyer une copie ailleurs dès qu'internet passe.
- **L'installation sur l'écran d'accueil du téléphone.** Sur une adresse en
  `http://`, le navigateur refuse d'activer le mode application. Un simple
  raccourci fait l'affaire ; si le mode application devient nécessaire, il
  faudra un certificat local installé sur chaque téléphone.
- **L'onduleur.** Il ne protège pas les données — SQLite survit à une coupure
  sèche — mais il évite de malmener le disque à chaque fois.
