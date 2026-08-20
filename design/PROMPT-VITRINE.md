# Prompt Claude Design — Vitrine des écrans livrés

Ce fichier sert à **montrer ce qui est construit**, pas à concevoir ce qui reste à faire.
Pour ça, voir `PROMPTS-CLAUDE-DESIGN.md`.

Au 20 août 2026, deux écrans existent réellement dans l'application et fonctionnent :
la connexion et l'enregistrement d'un prêt. Ce sont eux, et eux seuls, que ces prompts
mettent en image.

---

## Mode d'emploi

1. Va sur **claude.ai/design**, dans le projet `American Shelf Tiassale`.
2. Passe le **Prompt Vitrine** ci-dessous. Il contient le design system, il n'a besoin
   d'aucun prompt préalable.
3. Si le service répond « overloaded », utilise la version découpée en trois prompts,
   plus bas.

**Ce que ces prompts ne doivent pas faire :** inventer des écrans. Le tableau de bord,
la liste des abonnés et le catalogue public n'existent pas encore. Les faire dessiner
ici donnerait une vitrine qui ment sur l'état du projet.

---

## Différences entre les prompts d'origine et ce qui a été construit

À retenir avant de lire la suite, car ces écarts sont volontaires.

| Prévu à l'origine | Construit finalement | Pourquoi |
|---|---|---|
| Bandeau rouge de blocage pour l'abonnement expiré, bouton « Prolonger d'un an » | Bandeau ambre, bouton « Réinscrire pour un an » | L'adhésion est gratuite. Il n'y a rien à encaisser, la situation se règle d'un clic |
| « Encaisse le renouvellement au comptoir » | « La réinscription est gratuite, il suffit de la valider » | Même raison |
| Cotes de rangement absentes | Cotes affichées : COM-01, PRO-04 | Les 19 cotes ont été générées depuis la catégorie |
| Écran de succès avec bouton « Tableau de bord » | Bouton présent mais menant à l'écran de prêt | Le tableau de bord n'existe pas encore |

---

# PROMPT VITRINE

> À copier tel quel.

```
Crée une planche de présentation des deux écrans livrés d'une application de
bibliothèque communautaire, l'American Shelf de Tiassalé en Côte d'Ivoire, membre du
réseau American Spaces. Ces écrans existent et fonctionnent : la planche sert à les
montrer à des partenaires, pas à explorer des idées.

Présente les écrans comme des téléphones de 390 px de large posés sur une planche,
chacun légendé par un court titre et une phrase expliquant ce qu'il résout. Ton
institutionnel, sobre, jamais ludique.

COULEURS, à respecter exactement :
- navy #0A2240 (en-têtes, boutons primaires), survol #143A6B
- rouge #B31942 (surtitres, accents)
- bordure #E4E7EC, bordure forte #C9CFD6
- encre #1B1B1B, texte #3D4752, texte discret #5C6670, texte estompé #8A939C
- surface #F7F8FA, surface alternative #F1F4F8
États : disponible vert #0A6B3C sur #E7F4EC. Attention ambre #8A5200 sur #FCF3E3.
Retard ou blocage rouge #B31942 sur #FBEAEE.

TYPOGRAPHIE :
- Libre Franklin pour les titres, graisses 700 et 800, interlettrage -0.02em
- Public Sans pour le texte courant
- IBM Plex Mono pour les surtitres en majuscules avec interlettrage 0.12em, les cotes
  de rangement, les numéros de carte et les dates

FORMES : rayons de 4 px sur les boutons, 6 px sur les cartes, 999 px sur les puces et
les badges. Ombres discrètes uniquement au survol : 0 6px 18px rgba(10,34,64,0.10).

DESSINE HUIT ÉCRANS, dans cet ordre :

1. CONNEXION. Centré verticalement. Une marque faite de formes simples : carré navy de
56 px, coins à 4 px, contenant deux barres blanches horizontales. Dessous, le surtitre
rouge « AMERICAN SHELF DE TIASSALÉ » et le titre « Espace bibliothécaire ». Puis une
carte blanche contenant : libellé « Adresse email » et son champ, libellé « Mot de
passe » et son champ, bouton navy pleine largeur « Se connecter » de 60 px de haut.
Sous la carte, un lien discret « Mot de passe oublié ».

2. PRÊT, ÉTAPE 1, ÉTAT VIDE. En-tête navy collant en haut : surtitre « AMERICAN SHELF
DE TIASSALÉ » en petit sur fond navy, titre « Enregistrer un prêt », et à droite un
lien « Quitter ». Sous l'en-tête, un indicateur de trois étapes toujours visible :
pastille ronde navy avec « 1 » et le mot « Abonné », puis pastilles grises à contour
avec « 2 Ouvrage » et « 3 Confirmer ». Puis le titre « Qui emprunte ? », le libellé
« Nom ou numéro de carte », un champ de recherche suivi d'un bouton navy « Chercher ».
Enfin un état vide en cadre pointillé : « Commence par chercher l'abonné », et dessous
« Tape les premières lettres de son nom, ou scanne le numéro de sa carte ».

3. PRÊT, ÉTAPE 1, RÉSULTATS. Même en-tête. Le champ contient « Kon ». En dessous, des
lignes tactiles de 48 px minimum, chacune avec le nom en gras, le numéro de carte en
police monospace et en gris, et un badge à droite :
- Aminata Koné, TSL-2026-0087, badge vert « Peut emprunter »
- Kouadio N'Guessan, TSL-2026-0112, badge ambre « A déjà un livre »
- Ibrahim Traoré, TSL-2026-0233, badge rouge « Suspendu »
Un abonné n'a droit qu'à UN SEUL livre à la fois : l'état est binaire, il n'y a jamais
de compteur.

4. PRÊT, ÉTAPE 2. La pastille 1 est devenue verte avec une coche, la 2 est navy. En
haut, une carte « Abonné » : surtitre rouge « ABONNÉ », nom « Aminata Koné » en gras,
numéro « TSL-2026-0087 » en monospace, et à droite un bouton contour « Changer ».
Puis le titre « Quel ouvrage ? », un champ contenant « orateur », et deux résultats en
lignes tactiles. Chaque ligne porte, de haut en bas : la catégorie en surtitre rouge,
le titre sur deux lignes maximum, l'auteur, la cote en monospace gris, et à droite un
badge vert de disponibilité.
- COMMUNICATION & PRISE DE PAROLE / Devenez un grand orateur / « Auteur à renseigner »
  en italique gris estompé / Cote COM-01 / badge « 9 sur 10 disponibles »
- COMMUNICATION & PRISE DE PAROLE / Parlez, l'art de parler en public / « Auteur à
  renseigner » / Cote COM-02 / badge « 12 sur 12 disponibles »

5. PRÊT, ÉTAPE 3, CONFIRMATION. Les pastilles 1 et 2 sont vertes avec une coche, la 3
est navy. Titre « Vérifie et valide ». Une carte ouvrage : surtitre « OUVRAGE », titre
« Devenez un grand orateur », auteur en gris, badge vert et un lien « Changer ». Puis,
sur fond gris clair et centrée, la carte la plus importante de l'écran : surtitre
« À RAPPORTER LE » et, juste dessous, la date « 3 septembre 2026 » en très grand, en
navy, graisse 800. Sous la date, en petit et en gris : « Dans 14 jours, renouvelable
une fois ». Enfin un bouton navy pleine largeur de 60 px « Valider le prêt », et un
lien discret « Tout recommencer ».

6. PRÊT, ÉCRAN DE SUCCÈS. Une carte centrée : cercle vert clair de 64 px contenant une
coche verte, surtitre « PRÊT ENREGISTRÉ », nom « Aminata Koné » en gras, numéro de
carte en monospace, puis le titre entre guillemets français « Devenez un grand
orateur ». Un filet horizontal, puis le surtitre « À RAPPORTER LE » et la date
« 3 septembre 2026 » en grand navy. Sous la carte, deux boutons empilés pleine
largeur : « Nouveau prêt » en navy, « Tableau de bord » en contour.

7. BLOCAGE : L'ABONNÉ A DÉJÀ UN LIVRE. Étape 2 avec la carte de Kouadio N'Guessan,
TSL-2026-0112. Sous cette carte, un bandeau ambre à filet gauche de 4 px : en gras
« Cet abonné a déjà un livre en cours. », puis « « S'organiser pour réussir », à rendre
le 31 août 2026. », puis « Il doit le rapporter avant d'en emprunter un autre. »
Sous le bandeau, à la place de la recherche d'ouvrage, une phrase grise : « La recherche
d'ouvrage est désactivée tant que la situation ci-dessus n'est pas réglée. »

8. BLOCAGE : ADHÉSION EXPIRÉE. Étape 2 avec la carte d'Adjoua Brou, TSL-2026-0201.
Bandeau AMBRE, pas rouge, à filet gauche : en gras « Abonnement expiré depuis le
8 août 2026. », puis « La réinscription est gratuite, il suffit de la valider. », puis
un bouton navy de taille réduite « Réinscrire pour un an ». L'adhésion ne coûte rien :
aucun montant, aucun mode de paiement, aucun reçu ne doit apparaître.

RÈGLES VALABLES POUR TOUS LES ÉCRANS :
- Zones tactiles de 48 px minimum, texte de 16 px minimum. Le bibliothécaire est debout
  au comptoir avec un téléphone Android.
- Les titres du fonds sont longs, jusqu'à 52 caractères comme « S'organiser pour
  réussir, la méthode GTD spéciale ados ». Deux lignes autorisées, jamais de coupure
  au milieu d'un mot.
- Une partie des ouvrages n'a pas d'auteur : afficher « Auteur à renseigner » en
  italique gris estompé. C'est un travail en attente, pas une erreur.
- Aucune icône issue d'une bibliothèque. Les icônes sont des formes géométriques
  simples : carrés, cercles, barres, flèches, coches.

CONTRAINTE TECHNIQUE : produis du HTML avec des classes Tailwind CSS v4, et déclare
toutes les couleurs dans un bloc @theme réutilisable. Aucune bibliothèque externe.
```

---

## Version découpée, si le service est surchargé

Le prompt ci-dessus demande huit écrans d'un coup. Quand Claude Design est chargé, une
requête lourde échoue là où trois requêtes légères passent. Recolle alors le bloc
COULEURS, TYPOGRAPHIE et FORMES en tête de chaque prompt.

**Vitrine 1, la connexion et le point de départ** — écrans 1, 2 et 3.

**Vitrine 2, le parcours complet** — écrans 4, 5 et 6.

**Vitrine 3, les blocages** — écrans 7 et 8. Ce sont ceux qui font la différence entre
une maquette et un outil : ils montrent que l'application connaît les règles de la
bibliothèque.

---

## Données réelles à utiliser, jamais de Lorem ipsum

**Abonnés en base** et l'état que chacun illustre :

| Nom | Carte | Situation |
|---|---|---|
| Aminata Koné | TSL-2026-0087 | à jour, libre d'emprunter |
| Kouadio N'Guessan | TSL-2026-0112 | a un livre en cours, dans les délais |
| Fatou Diarra | TSL-2026-0034 | a un livre en retard de 6 jours |
| Yao Kouassi | TSL-2026-0155 | adhésion expirant dans 18 jours |
| Adjoua Brou | TSL-2026-0201 | adhésion expirée |
| Ibrahim Traoré | TSL-2026-0233 | suspendu |

**Ouvrages et cotes**, les plus utiles pour les maquettes :

| Cote | Titre | Ex. |
|---|---|---|
| COM-01 | Devenez un grand orateur | 10 |
| COM-02 | Parlez, l'art de parler en public | 12 |
| COM-03 | Écoutez, l'art de la communication attentive | 7 |
| PRO-03 | S'organiser pour réussir | 7 |
| PRO-04 | S'organiser pour réussir, la méthode GTD spéciale ados | 7 |
| PRO-06 | The One Thing, passez à l'essentiel | 2 |
| DEV-03 | Le Grain de Café | 5 |
| BIO-01 | Mohamed Ali, le plus Grand | 5 |

**Règles à refléter partout** : prêt de 14 jours, renouvelable une seule fois. Un seul
livre par abonné à la fois. Adhésion gratuite, valable un an. Aucun paiement n'apparaît
jamais dans l'application.
