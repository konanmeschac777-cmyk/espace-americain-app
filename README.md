# American Shelf de Tiassalé

Le logiciel de prêt de la bibliothèque de l'American Shelf de Tiassalé, en
Côte d'Ivoire. Il tient le fonds, les abonnés et les emprunts, et se manie
depuis un téléphone posé sur le comptoir.

**Il fonctionne sans internet.** Un poste de la salle informatique fait
serveur, les téléphones l'atteignent par le Wi-Fi de la bibliothèque, et
rien ne sort du bâtiment. C'est la contrainte qui a décidé de presque tout
le reste : pas d'envoi d'e-mail, pas de service extérieur, une base de
données qui tient dans un fichier qu'on peut copier sur une clé USB.

> **Pour installer le serveur de l'Espace, tout est dans
> [`deploy/README.md`](deploy/README.md)** — neuf étapes, d'Ubuntu à la
> sauvegarde automatique du soir.

---

## Ce que fait l'application

| Écran | À quoi il sert |
|---|---|
| Prêt | Enregistrer un emprunt en trois gestes : l'abonné, le livre, la confirmation |
| Retour | Rendre un livre au comptoir, avec le retard s'il y en a un |
| Emprunts | Ce qui est dehors, les retards en tête |
| Abonnés | Inscrire, retrouver, réinscrire, suspendre |
| Catalogue | Le fonds, les exemplaires disponibles, les cotes de rangement |
| Tableau de bord | Ce qu'il faut relancer aujourd'hui |
| Rapport du mois | Les chiffres à présenter au réseau American Spaces |

Les règles du comptoir ne sont pas codées en dur. Elles vivent dans la table
`settings` et se changent sans redéployer :

| Réglage | Défaut | Ce qu'il décide |
|---|---|---|
| `loan_days` | 14 | Durée d'un prêt |
| `max_renewals` | 1 | Renouvellements autorisés |
| `loan_quota` | 1 | Livres simultanés par abonné |
| `membership_months` | 12 | Durée de l'adhésion, qui est gratuite |
| `card_prefix` | TSL | Préfixe des numéros de carte (TSL-2026-0087) |

---

## Monter le projet sur son poste

Il faut **Ruby 3.4.10** (la version exacte est dans `.ruby-version`). Le reste
s'installe tout seul :

```bash
git clone <ce-dépôt>
cd espace-americain-app
bin/setup
```

`bin/setup` installe les dépendances, prépare la base et démarre le serveur.
Ensuite, au quotidien :

```bash
bin/dev      # serveur + compilation continue de Tailwind (http://localhost:3000)
```

### Se donner de quoi travailler

La base est vide au départ. Deux commandes la remplissent :

```bash
bin/rails db:seed     # le fonds réel : 19 titres, 93 exemplaires, les catégories
bin/rails demo:load   # des abonnés et des prêts d'exemple, pour voir les écrans
```

`db:seed` est idempotent, on peut le relancer sans créer de doublons.
`demo:load` refuse de tourner en production — ces données ne doivent jamais
atteindre le comptoir. `demo:clear` les enlève.

Il n'y a pas d'écran d'inscription, et c'est voulu : un espace bibliothécaire
ne doit pas laisser un inconnu se créer un compte. Les comptes se créent en
ligne de commande.

```bash
bin/rails "bibliothecaire:creer[toi@exemple.ci,motdepasse]"
bin/rails bibliothecaire:lister
```

La même commande redonne un mot de passe à un compte existant. C'est elle que
l'écran « mot de passe oublié » affiche sur le serveur de l'Espace, puisque
aucun e-mail ne peut en partir.

---

## Vérifier son travail

```bash
bin/rails test          # 150 tests, quelques secondes
bin/rails test:system   # 4 parcours dans un vrai Chrome, une vingtaine de secondes
bin/rubocop             # style
bin/brakeman            # failles courantes
```

Les cinq mêmes vérifications tournent sur GitHub Actions à chaque push sur
`main` et à chaque pull request.

Deux choses à savoir avant d'écrire un test :

- **Les prêts ne sont pas en fixtures.** Un prêt n'existe qu'en relation à
  aujourd'hui — un retard de six jours, une échéance à deux jours. Une fixture
  figée dirait autre chose chaque semaine. `LibraryTestHelper` les fabrique à
  la demande : `pret_en_cours(book:, member:, en_retard_de: 6)`.
- **Les tests système ne portent aucune règle métier.** Les modèles s'en
  chargent, et cent fois plus vite. On n'y met que des parcours complets.

---

## Comment c'est fait

Rails 8.1 et Ruby 3.4, SQLite, Tailwind v4, Hotwire (Turbo et Stimulus) via
import maps. Aucun service à faire tourner à côté : ni Redis, ni serveur de
base de données, ni CDN — le cache et la file d'attente sont eux aussi des
fichiers SQLite, et les polices sont servies par l'application. C'est la
conséquence directe du serveur sans internet.

```
app/models/          Les règles : qui peut emprunter, quand un prêt est en retard
app/controllers/     Un contrôleur par geste du comptoir
app/views/           Les écrans, dessinés pour un téléphone
lib/tasks/           Comptes, cotes de rangement, données de démonstration
db/seeds.rb          Le fonds réel de l'Espace
deploy/              L'installation du serveur de l'Espace
design/              Les maquettes dont sont sortis les écrans
test/                150 tests + 4 parcours navigateur
```

### Trois décisions qui expliquent le reste

**La disponibilité d'un livre n'est pas stockée**, elle se calcule en retirant
les prêts en cours du nombre d'exemplaires. Un compteur en base finit toujours
par mentir, dès le premier incident.

**Un prêt est terminé quand `returned_on` cesse d'être nul.** Il n'y a pas de
colonne « statut » à tenir à jour, donc pas de colonne qui puisse se
désynchroniser de la réalité.

**Les chemins des URL sont en français, le code reste en anglais.** Le
bibliothécaire lit `/prets/nouveau` dans son navigateur ; le développeur lit
`LoansController`. Les commentaires, eux, sont en français : ils s'adressent à
qui reprendra ce code à Tiassalé.

---

## Ce qui n'est pas encore fait

- Les réglages du tableau ci-dessus ne s'éditent qu'en console, pas depuis
  l'application.
- Le catalogue public en ligne, deuxième moitié du projet, n'existe pas.
- 43 clés de traduction d'infrastructure manquent en anglais. Sans effet
  visible aujourd'hui : Rails fournit l'anglais par défaut.
- `deploy/README.md` tient sa propre liste, côté serveur : poste de secours,
  copie hors du bâtiment, onduleur.
