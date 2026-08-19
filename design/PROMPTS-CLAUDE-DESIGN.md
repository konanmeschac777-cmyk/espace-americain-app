# Prompts Claude Design — American Shelf de Tiassalé

Tous les prompts de l'interface, dans l'ordre où les passer. Chaque bloc de code se copie-colle tel quel dans Claude Design.

---

## Mode d'emploi

1. Va sur **claude.ai/design** et crée un projet nommé `American Shelf Tiassale`.
2. Passe le **Prompt 0** en premier, une seule fois. Il fixe les couleurs, la typographie et les composants. Tout le reste en dépend.
3. Ensuite un écran, un prompt, dans l'ordre. **Tu valides avant de passer au suivant.** Un prompt qui demande cinq écrans d'un coup produit cinq écrans moyens.
4. Si un écran ne te plaît pas, ne repars pas de zéro. Dis ce qui cloche précisément : "les boutons de validation sont trop petits pour le pouce", "le titre est coupé sur deux lignes".
5. Quand un écran est validé, on le porte en partial ERB dans l'application Rails. Claude Design produit du HTML avec des classes Tailwind, pas des vues Rails : le portage reste du travail réel, mais il se réduit à un copier-coller suivi du branchement sur les données.

### L'ordre compte

Les écrans 1 à 4 sont ceux que le bibliothécaire utilisera cent fois par semaine. Les écrans publics sont une vitrine. Si tu dois t'arrêter en cours de route, arrête-toi après l'écran 9, tu auras une application utilisable.

---

## Règles à rappeler dans chaque prompt

Ces contraintes sont dans le Prompt 0, mais Claude Design a tendance à les oublier au bout de quelques écrans. Recolle-les si tu vois dériver.

- **Back-office : mobile d'abord, cible 390 px de large.** Le bibliothécaire travaille sur un téléphone Android, debout, au comptoir.
- **Zones tactiles de 48 px minimum, texte de 16 px minimum.** En dessous, c'est inutilisable au pouce.
- **HTML avec classes Tailwind CSS.** Aucune bibliothèque externe, aucune icône issue d'un paquet. Les icônes sont des formes géométriques simples.
- **Toujours dessiner l'état vide et les états d'erreur**, pas seulement le cas idéal. C'est ce qui sépare une maquette d'un écran exploitable.
- **Les titres du fonds sont longs et certains n'ont pas d'auteur.** L'affichage doit tenir dans les deux cas.

---

## Données d'exemple à utiliser

Utilise ces données réelles dans les maquettes, pas des `Lorem ipsum`. Une maquette avec de vraies données révèle les problèmes de mise en page tout de suite.

**Ouvrages réels du fonds** (19 titres, 93 exemplaires, livraison Nouveaux Horizons mai 2026) :

| Titre | Ex. | Catégorie |
|---|---|---|
| Parlez, l'art de parler en public | 12 | Communication |
| Devenez un grand orateur | 10 | Communication |
| Écoutez, l'art de la communication attentive | 7 | Communication |
| Team, s'organiser pour réussir en équipe | 7 | Productivité |
| S'organiser pour réussir | 7 | Productivité |
| S'organiser pour réussir, la méthode GTD spéciale ados | 7 | Productivité |
| Préparer un examen | 7 | Productivité |
| L'effet cumulé, décuplez votre réussite | 5 | Productivité |
| La Montagne, c'est toi | 5 | Développement personnel |
| Mohamed Ali, le plus Grand | 5 | Biographies |
| Le Grain de Café | 5 | Développement personnel |
| The One Thing, passez à l'essentiel | 2 | Productivité |
| La Théorie Let Them | 2 | Développement personnel |
| Le Management Multiplicateur | 2 | Leadership |
| Leadership, Stratégie & Tactique | 2 | Leadership |
| Le Prix de l'Excellence | 2 | Leadership |
| Les 7 secrets de Warren Buffet pour devenir riche | 2 | Entrepreneuriat |
| Devenir Business Coach | 2 | Entrepreneuriat |
| Devenez Riche, programme de 6 semaines | 2 | Entrepreneuriat |

**Abonnés d'exemple** : Aminata Koné (TSL-2026-0087), Kouadio N'Guessan (TSL-2026-0112), Fatou Diarra (TSL-2026-0034), Yao Kouassi (TSL-2026-0155), Adjoua Brou (TSL-2026-0201).

**Règles métier à refléter partout** : prêt de 14 jours, renouvelable une seule fois. Un seul livre par abonné à la fois. Abonnement valable un an. Le paiement se fait au comptoir, il n'apparaît jamais dans l'application.

---

# PROMPT 0 — La fondation

> À passer en premier, une seule fois.

```
Crée le design system d'une application de bibliothèque communautaire, l'American Shelf de Tiassalé en Côte d'Ivoire, membre du réseau American Spaces. Ton institutionnel, sobre, lisible, jamais ludique. L'application sert un vrai lieu, pas une démo.

COULEURS, à respecter exactement :
- navy #0A2240 (couleur principale, en-têtes, boutons primaires), survol #143A6B
- rouge #B31942 (accents, surtitres, actions destructives), survol #8E1435
- bordure #E4E7EC, bordure forte #C9CFD6
- encre #1B1B1B, texte #3D4752, texte discret #5C6670, texte estompé #8A939C
- surface #F7F8FA, surface alternative #F1F4F8
États : disponible, vert #0A6B3C sur fond #E7F4EC. Attention ou bientôt dû, ambre #8A5200 sur fond #FCF3E3. Indisponible ou en retard, rouge #B31942 sur fond #FBEAEE.

TYPOGRAPHIE :
- Libre Franklin pour les titres, graisses 700 et 800, interlettrage -0.02em sur les grands titres
- Public Sans pour le texte courant
- IBM Plex Mono pour les surtitres en majuscules avec interlettrage 0.12em, les cotes de rangement et les dates

FORMES : rayons de 4 px sur les boutons, 6 px sur les cartes, 999 px sur les puces de filtre. Ombres discrètes et uniquement au survol : 0 6px 18px rgba(10,34,64,0.10).

COMPOSANTS À LIVRER :
- Boutons : primaire navy, secondaire contour, rouge, désactivé. Trois tailles. Version pleine largeur.
- Champ de saisie avec libellé, aide et message d'erreur
- Champ de recherche avec bouton d'effacement
- Puce de filtre, active et inactive
- Badge d'état dans les quatre couleurs
- Carte d'ouvrage avec zone de couverture, catégorie, titre, auteur, badge de disponibilité
- Ligne de liste dense, tactile, pour les listes d'abonnés et d'emprunts
- Tuile de statistique, grand chiffre et libellé
- Fenêtre modale
- État vide, avec message et action
- Bandeau d'alerte, en version information, attention et blocage
- Barre de navigation basse à quatre onglets pour mobile
- En-tête d'écran back-office, avec bouton retour et titre

DEUX CONTEXTES DE MISE EN PAGE :
- Back-office, mobile d'abord, cible 390 px. Zones tactiles de 48 px minimum, texte de 16 px minimum. L'utilisateur est debout au comptoir, avec un téléphone Android.
- Portail public, cible 1240 px avec déclinaison mobile.

CONTRAINTE TECHNIQUE : produis du HTML avec des classes Tailwind CSS v4, et déclare toutes les couleurs ci-dessus dans un bloc @theme réutilisable tel quel. Aucune bibliothèque externe, aucune icône issue d'un paquet. Les icônes sont des formes géométriques simples, carrés, cercles, barres.
```

---

## PROMPT 0 en version découpée — si Claude Design répond "overloaded"

> Le Prompt 0 demande 13 composants en une seule génération. Quand le service est
> chargé, une requête lourde échoue là où trois requêtes légères passent.
> Utilise cette version de secours, dans l'ordre 0A, 0B, 0C.

**0A, les fondations**

```
Crée les fondations du design system d'une application de bibliothèque communautaire, l'American Shelf de Tiassalé en Côte d'Ivoire, membre du réseau American Spaces. Ton institutionnel, sobre, lisible, jamais ludique.

COULEURS, exactement :
navy #0A2240 (principale), survol #143A6B. Rouge #B31942 (accents, surtitres), survol #8E1435. Bordure #E4E7EC, bordure forte #C9CFD6. Encre #1B1B1B, texte #3D4752, texte discret #5C6670, texte estompé #8A939C. Surface #F7F8FA, surface alternative #F1F4F8.
États : disponible vert #0A6B3C sur #E7F4EC. Attention ambre #8A5200 sur #FCF3E3. Retard rouge #B31942 sur #FBEAEE.

TYPOGRAPHIE : Libre Franklin pour les titres, graisses 700 et 800, interlettrage -0.02em sur les grands titres. Public Sans pour le texte courant. IBM Plex Mono pour les surtitres en majuscules avec interlettrage 0.12em, les cotes et les dates.

FORMES : rayons de 4 px sur les boutons, 6 px sur les cartes, 999 px sur les puces de filtre. Ombres uniquement au survol : 0 6px 18px rgba(10,34,64,0.10).

Livre une page unique montrant la palette, l'échelle typographique et les rayons.

CONTRAINTE : HTML avec classes Tailwind CSS v4, et toutes les couleurs déclarées dans un bloc @theme réutilisable tel quel. Aucune bibliothèque externe.
```

**0B, les composants d'action**

```
En reprenant les fondations précédentes, dessine les composants d'interaction :
- Boutons : primaire navy, secondaire contour, rouge, désactivé. Trois tailles. Version pleine largeur.
- Champ de saisie avec libellé, texte d'aide et message d'erreur
- Champ de recherche avec bouton d'effacement
- Puce de filtre, active et inactive
- Badge d'état dans les quatre couleurs : disponible, attention, retard, neutre

Zones tactiles de 48 px minimum, texte de 16 px minimum. L'utilisateur est un bibliothécaire debout au comptoir, avec un téléphone Android.
Mêmes contraintes techniques : HTML et classes Tailwind, aucune bibliothèque externe.
```

**0C, les composants d'affichage**

```
En reprenant les fondations et les composants précédents, dessine :
- Carte d'ouvrage : zone de couverture, catégorie en surtitre, titre, auteur, badge de disponibilité
- Ligne de liste dense et tactile, pour les listes d'abonnés et d'emprunts
- Tuile de statistique : grand chiffre et libellé
- Fenêtre modale
- État vide, avec message et action
- Bandeau d'alerte en trois versions : information, attention, blocage
- Barre de navigation basse à quatre onglets pour mobile
- En-tête d'écran back-office, avec bouton retour et titre

Contrainte : les titres d'ouvrages sont longs, jusqu'à 52 caractères comme "S'organiser pour réussir, la méthode GTD spéciale ados". La carte et la ligne de liste doivent tenir sur deux lignes sans troncature brutale. Certains ouvrages n'ont pas d'auteur, l'affichage doit rester propre.
Mêmes contraintes techniques : HTML et classes Tailwind, aucune bibliothèque externe.
```

> Si la surcharge persiste : Claude Design est un confort, pas une dépendance.
> Le design system peut être produit directement dans Claude Code, en HTML et
> Tailwind, à partir des mêmes spécifications. Le projet n'est jamais bloqué.

---

# BACK-OFFICE

## PROMPT 1 — Prêt rapide ⭐

> L'écran le plus important de toute l'application. Si sa prise en main dépasse 30 secondes, le bibliothécaire reprendra son cahier papier. Passe du temps ici.

```
Écran "Enregistrer un prêt" du back-office, mobile 390 px, en utilisant le design system.

Trois étapes numérotées visibles en permanence en haut de l'écran.

ÉTAPE 1, trouver l'abonné : champ de recherche par nom ou numéro de carte. Résultats en lignes tactiles avec le nom, le numéro de carte, et un badge d'état binaire, soit "Peut emprunter" en vert, soit "A déjà un livre" en ambre. Un abonné n'a droit qu'à UN SEUL livre à la fois, il n'y a donc pas de compteur. La ligne choisie devient une carte abonné sélectionnée, avec un bouton "Changer".

ÉTAPE 2, trouver l'ouvrage : même principe. Résultats avec titre, auteur, cote de rangement, et badge "5 sur 7 disponibles".

ÉTAPE 3, confirmer : récapitulatif abonné plus ouvrage, date de retour calculée affichée en très grand, 14 jours après aujourd'hui, et un bouton principal pleine largeur "Valider le prêt".

DESSINE LES QUATRE ÉTATS BLOQUANTS, chacun avec un bandeau d'alerte explicite qui désactive la validation :
1. L'abonné a déjà un livre en cours, avec le titre et la date de retour prévue
2. Son abonnement annuel est expiré, avec un bouton d'action "Prolonger d'un an"
3. Il est suspendu
4. L'ouvrage n'a plus aucun exemplaire disponible

DESSINE AUSSI :
- L'écran de succès : coche, nom de l'abonné, titre, date de retour, boutons "Nouveau prêt" et "Tableau de bord"
- L'état vide de la recherche, avant toute frappe
- L'état "aucun résultat"

CONTRAINTES : certains titres n'ont pas d'auteur renseigné, l'affichage doit rester propre. Les titres sont longs, par exemple "S'organiser pour réussir, la méthode GTD spéciale ados", prévois deux lignes sans troncature brutale.
```

## PROMPT 2 — Retour rapide

```
Écran "Enregistrer un retour" du back-office, mobile 390 px, avec le design system.

Un seul champ de recherche en haut, qui cherche à la fois dans les noms d'abonnés et les titres, mais UNIQUEMENT parmi les livres actuellement sortis. C'est la clé de la rapidité, on ne cherche pas dans tout le catalogue.

Sous la recherche, la liste des emprunts en cours, triée avec les retards en premier. Chaque ligne montre le titre, le nom de l'abonné, la date d'échéance, un badge d'état, "Dans les délais" en vert, "À rendre dans 2 jours" en ambre, "En retard de 5 jours" en rouge, et un bouton "Retourner" à droite.

Le bouton "Retourner" ouvre une confirmation courte, pas une modale lourde.

DESSINE :
- L'écran de succès après un retour, avec mention du retard s'il y en avait un, et la précision que l'abonné peut maintenant emprunter à nouveau
- L'état vide, "Aucun livre n'est actuellement emprunté"
- L'état "aucun résultat" pour la recherche
```

## PROMPT 3 — Tableau de bord

```
Tableau de bord du back-office, écran d'accueil après connexion, mobile 390 px, avec le design system.

En haut, deux boutons d'action très grands, pleine largeur, empilés : "Prêter un livre" en navy et "Enregistrer un retour" en contour. Ce sont les deux gestes du quotidien, ils doivent être atteignables au pouce sans réfléchir.

En dessous, quatre tuiles de statistique sur deux colonnes : livres actuellement sortis, retards, abonnés actifs, prêts cette semaine. La tuile "retards" passe en rouge si le nombre est supérieur à zéro.

Puis deux listes courtes, trois lignes chacune avec un lien "Tout voir" :
1. "À relancer", les emprunts en retard, avec le titre, le nom de l'abonné, le nombre de jours de retard et son numéro de téléphone affiché en toutes lettres pour pouvoir appeler
2. "Abonnements à renouveler", les abonnés dont l'abonnement expire dans moins de 30 jours

En bas, une barre de navigation à quatre onglets : Accueil, Prêts, Ouvrages, Abonnés.

DESSINE AUSSI la version "journée calme" : zéro retard, zéro abonnement à renouveler. Les listes affichent un état vide positif, pas un vide brut.
```

## PROMPT 4 — Emprunts et retards

```
Écran "Emprunts" du back-office, mobile 390 px, avec le design system.

En haut, quatre puces de filtre : Tous, En cours, Bientôt dus, En retard. Le compteur apparaît dans la puce, par exemple "En retard (3)".

Liste d'emprunts en lignes denses. Chaque ligne : titre de l'ouvrage, nom de l'abonné et son numéro de carte, date d'échéance, badge d'état coloré. Les retards remontent toujours en tête, triés du plus ancien au plus récent.

Un appui sur une ligne ouvre un panneau d'actions : "Enregistrer le retour", "Renouveler 14 jours", "Appeler l'abonné". Le renouvellement n'est possible qu'une seule fois. Dessine explicitement l'état où le bouton "Renouveler" est désactivé avec la mention "Déjà renouvelé une fois".

DESSINE : l'état vide pour chaque filtre, et la ligne d'un emprunt très en retard, plus de 30 jours, qui doit se distinguer visuellement des retards de quelques jours.
```

## PROMPT 5 — Liste des ouvrages

```
Écran "Ouvrages" du back-office, mobile 390 px, avec le design system.

En haut : champ de recherche, puis des puces de filtre par catégorie, Toutes, Communication, Productivité, Leadership, Entrepreneuriat, Développement personnel, Biographies.

Une puce de filtre supplémentaire, distincte visuellement des autres : "À compléter", qui isole les fiches sans auteur ou sans catégorie. Le catalogue a été importé depuis un fichier qui ne contenait que les titres et les quantités, une bonne partie des fiches est donc incomplète. Cette puce affiche un compteur.

Liste en lignes denses : titre, auteur ou la mention "Auteur à renseigner" en texte estompé et italique, catégorie, et un badge "5 sur 7 disponibles". Les fiches incomplètes portent un petit marqueur ambre.

Un bouton flottant "Ajouter un ouvrage" en bas à droite.

DESSINE : l'état vide de recherche, et la vue filtrée "À compléter" qui doit donner envie de traiter la file, avec un message du type "12 fiches à compléter".
```

## PROMPT 6 — Fiche ouvrage, ajout et édition

```
Formulaire d'ajout et d'édition d'un ouvrage, back-office, mobile 390 px, avec le design system.

Champs, dans cet ordre :
- Titre, obligatoire
- Auteur, FACULTATIF, avec l'aide "Laisse vide si tu ne le connais pas encore"
- Catégorie, liste déroulante des six catégories
- Langue, français par défaut
- Nombre d'exemplaires, avec des boutons plus et moins de chaque côté du chiffre, tactiles
- Cote de rangement, facultatif
- Collection, "Nouveaux Horizons" par défaut
- Date de réception
- Résumé, zone de texte facultative

En bas, bouton "Enregistrer" pleine largeur, et un lien discret "Archiver cet ouvrage" en mode édition seulement.

DESSINE TROIS VARIANTES :
1. Le formulaire vide, en création
2. Le formulaire en édition, prérempli avec "Parlez, l'art de parler en public", 12 exemplaires
3. Le mode "compléter une fiche", où le titre et la quantité sont déjà là et où seuls l'auteur et la catégorie sont à remplir. Cet écran s'enchaîne fiche après fiche, prévois un bouton "Enregistrer et passer à la suivante" avec un indicateur de progression du type "3 sur 12".
```

## PROMPT 7 — Liste des abonnés

```
Écran "Abonnés" du back-office, mobile 390 px, avec le design system.

Champ de recherche par nom ou numéro de carte.

Puces de filtre : Tous, Actifs, Expire bientôt, Expirés, Suspendus. L'abonnement dure un an, ces filtres servent à voir venir les renouvellements.

Liste en lignes denses. Chaque ligne : nom et prénom, numéro de carte en police monospace, badge d'état de l'abonnement, "Actif jusqu'au 12 mars 2027" en vert, "Expire dans 18 jours" en ambre, "Expiré depuis le 3 août 2026" en rouge, et un second badge indiquant s'il a un livre en cours.

Bouton flottant "Nouvel abonné" en bas à droite.

DESSINE : l'état vide, et la vue filtrée "Expire bientôt" avec quatre abonnés, celle que le bibliothécaire consultera en début de mois.
```

## PROMPT 8 — Fiche abonné

```
Fiche détaillée d'un abonné, back-office, mobile 390 px, avec le design system.

En haut, une carte d'identité : nom et prénom, numéro de carte en gros et en monospace, téléphone, date d'adhésion, date d'expiration, badge d'état de l'abonnement.

Sous cette carte, deux boutons : "Prêter un livre" en navy, et "Prolonger d'un an" en contour. Le second sert au renouvellement annuel, une fois que le bibliothécaire a encaissé le paiement au comptoir. Le paiement lui-même n'est PAS géré par l'application, ne dessine aucun champ de montant, de mode de paiement ni de reçu.

Ensuite, "Emprunt en cours" : soit une carte avec le titre, la date d'échéance, le badge d'état et un bouton "Retourner", soit un état vide "Aucun emprunt en cours".

Enfin, "Historique", un tableau simple à trois colonnes, ouvrage, emprunté le, retourné le, limité aux dix derniers avec la mention du reste.

DESSINE TROIS VARIANTES : abonné actif sans emprunt, abonné avec un livre en retard, abonné dont l'abonnement est expiré, où le bouton "Prêter un livre" est désactivé et où un bandeau invite à prolonger.
```

## PROMPT 9 — Statistiques

```
Écran "Statistiques" du back-office, mobile 390 px puis version large, avec le design system.

Ces chiffres servent au reporting vers le réseau American Spaces et l'ambassade, ils doivent être présentables tels quels.

Contenu :
- Quatre tuiles : prêts ce mois, prêts depuis le début, abonnés actifs, taux de retour dans les délais en pourcentage
- Un graphique en barres verticales, prêts par mois sur douze mois, en navy, sans bibliothèque externe, uniquement des div en CSS
- "Les plus empruntés", top 10 en lignes numérotées avec le titre et le nombre de prêts, avec une barre de proportion horizontale
- "Répartition par catégorie", six lignes avec le nom de la catégorie, le nombre de prêts et une barre de proportion
- Un sélecteur de période en haut : 30 jours, 3 mois, 12 mois, tout

DESSINE l'état "pas encore assez de données", celui des premières semaines après la mise en service. C'est ce que le bibliothécaire verra en vrai au démarrage, il ne doit pas avoir l'impression que l'écran est cassé.
```

## PROMPT 10 — Connexion et messages

```
Deux écrans du back-office, mobile 390 px, avec le design system.

ÉCRAN A, connexion : logo de l'American Shelf, titre "Espace bibliothécaire", champ email, champ mot de passe, bouton "Se connecter" pleine largeur, et un lien "Mot de passe oublié". Dessine l'état d'erreur "Email ou mot de passe incorrect" et l'état de chargement du bouton.

ÉCRAN B, messages reçus : liste des messages envoyés depuis le formulaire de contact du site public. Chaque ligne montre le nom, le sujet, la date, un extrait du message, et un point de couleur pour les non traités. Un appui ouvre le message complet avec le bouton "Marquer comme traité". Filtres : Tous, Non traités, Traités. Dessine l'état vide.
```

---

# PORTAIL PUBLIC

> Ces écrans existent déjà en HTML dans la maquette. Les prompts servent à les corriger et à les brancher sur de vraies données, pas à les réinventer.

## PROMPT 11 — Catalogue public

```
Page "Catalogue" du site public, largeur 1240 px avec déclinaison mobile, avec le design system.

Bandeau de titre : surtitre "Catalogue", titre "Consultez et empruntez les ouvrages de l'Espace", texte d'introduction, et à droite deux chiffres, "19 titres au catalogue" et "93 exemplaires".

Panneau de filtres : champ de recherche par titre ou auteur, puis des puces de catégorie, Toutes, Communication, Productivité, Leadership, Entrepreneuriat, Développement personnel, Biographies. Puis un filtre de disponibilité, Tous, Disponible, Emprunté. PAS de filtre de langue, tout le fonds est en français.

Grille de cartes d'ouvrage, sans pagination, les 19 titres tiennent sur une page. Chaque carte : zone de couverture, catégorie en surtitre rouge, titre, auteur ou rien du tout si absent, et un badge de disponibilité, "Disponible" en vert ou "Emprunté, retour le 12 septembre" en rouge.

RÈGLE ABSOLUE : le badge d'un livre emprunté n'affiche JAMAIS le nom de la personne qui l'a emprunté. Uniquement l'état et la date de retour.

Pas de bouton "Emprunter" sur le site public. L'emprunt se fait sur place. À la place, un lien "Voir la fiche".

DESSINE : l'état "aucun résultat", et une carte sans auteur, pour vérifier que la mise en page ne s'effondre pas.
```

## PROMPT 12 — Fiche ouvrage publique

```
Page de détail d'un ouvrage sur le site public, largeur 1240 px avec déclinaison mobile, avec le design system. Cette page remplace la fenêtre modale actuelle, elle doit être trouvable sur Google.

Deux colonnes sur grand écran : à gauche une grande zone de couverture, à droite les informations.

À droite : catégorie en surtitre, titre en très grand, auteur, résumé, puis un bloc de caractéristiques sur deux colonnes, langue, exemplaires, cote de rangement, durée de prêt de 14 jours. Puis le badge de disponibilité en évidence.

Sous le badge, un encart explicatif : "L'emprunt se fait sur place, à l'Espace, sur présentation de votre carte d'abonné", avec les horaires et un lien "Devenir abonné".

En bas de page, "Dans la même catégorie", trois cartes d'ouvrage.

DESSINE deux variantes : ouvrage disponible, et ouvrage entièrement emprunté avec la date de retour la plus proche.
```

## PROMPT 13 — Devenir abonné et accueil

```
Deux pages du site public, largeur 1240 px avec déclinaison mobile, avec le design system.

PAGE A, "Devenir abonné". Elle remplace l'ancienne page "Mon espace". Contenu : ce que donne l'abonnement, les conditions d'inscription, les pièces à fournir, la durée d'un an, le fait que l'inscription et le paiement se font uniquement sur place, les horaires, et les règles d'emprunt, un livre à la fois, 14 jours, renouvelable une fois. Une frise en trois étapes : se présenter avec une pièce d'identité, remplir la fiche, recevoir sa carte. Ton accueillant, phrases courtes.

PAGE B, refonte du bandeau de chiffres de la page d'accueil. Les chiffres actuels du site sont inventés et doivent disparaître. Remplace-les par quatre chiffres réels et vérifiables : 93 livres sur les étagères, 19 titres, le nombre d'abonnés inscrits, le nombre de prêts ce mois. Garde le style de bandeau existant, barre rouge au-dessus de chaque chiffre sur fond navy.
```

---

## Après la validation des maquettes

Une fois les écrans validés dans Claude Design, l'ordre de portage en vues ERB est celui du plan : authentification, ouvrages, abonnés, prêt, retour, emprunts, tableau de bord, puis le portail public.

Le bloc `@theme` produit par le Prompt 0 se copie une seule fois dans `app/assets/tailwind/application.css`. Tous les écrans suivants réutilisent alors les mêmes noms de couleurs sans qu'on ait rien à retraduire.

Ne porte pas les écrans dans l'ordre où tu les as dessinés. Porte-les dans l'ordre où ils deviennent testables avec de vraies données.
