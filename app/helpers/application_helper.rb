module ApplicationHelper
  # Le tiroir de navigation (écran 24) suppose une session ouverte : absent
  # de l'accueil, de la connexion et des écrans de mot de passe. Seule
  # autre exception : au milieu d'un prêt qui n'est pas bloqué (recherche
  # de l'abonné, de l'ouvrage, confirmation, ou recherche sans résultat),
  # la seule sortie reste le ✕, pas de tiroir. Un prêt bloqué (06, 07) ou
  # déjà confirmé (05, le reçu) rouvre l'accès au tiroir normalement.
  def tiroir_visible?
    return false unless authenticated?
    return true unless controller_name == "loans" && action_name == "new"

    @confirmed_loan.present? || @member&.borrow_block_reason.present?
  end

  # Options du sélecteur d'indicatif téléphonique (formulaires abonné).
  def options_indicatifs_telephoniques(selectionne)
    options_for_select(
      Member::INDICATIFS_TELEPHONIQUES.map { |code, nom, iso| [ "#{Member.drapeau(iso)} #{code} #{nom}", code ] },
      selectionne
    )
  end

  # Initiales du bibliothécaire connecté, pour l'avatar du tiroir.
  def initiales_utilisateur
    Current.user.initials
  end

  # Choisit entre une clé de traduction au singulier et une au pluriel,
  # selon la règle de la langue active : le français reste au singulier
  # pour 0 et 1 ("0 jour", "1 jour"), l'anglais ne l'est que pour 1
  # ("0 days", "1 day"). Sans le gem rails-i18n, le pluriel intégré à
  # Rails ne fait pas cette distinction pour le français : on la fait ici.
  def pluriel(nombre, singulier:, pluriel:)
    au_singulier = I18n.locale == :fr ? nombre <= 1 : nombre == 1
    t(au_singulier ? singulier : pluriel)
  end

  # Nom d'une catégorie, traduit. Les six catégories forment une
  # taxonomie fixe de l'interface (comme les libellés du tiroir), pas une
  # donnée d'utilisateur : elles se traduisent, contrairement aux titres
  # et noms d'auteurs qui restent dans leur langue d'origine.
  def nom_categorie(category)
    t("app.categories.#{category.slug}", default: category.name)
  end

  # Auteur d'un ouvrage, ou la mention qui invite à le renseigner.
  # Le fonds a été importé sans les auteurs : l'absence est le cas courant,
  # elle ne doit pas ressembler à un bug.
  def auteur(book)
    if book.author_display
      book.author_display
    else
      tag.span t("app.badges.auteur_a_renseigner"), class: "auteur-manquant"
    end
  end

  # "5 sur 7 disponibles", coloré selon qu'il reste ou non un exemplaire.
  def badge_disponibilite(book)
    libre = book.copies_available

    if libre.positive?
      tag.span t("app.badges.disponibles", n: libre, total: book.total_copies), class: "badge badge-dispo"
    else
      tag.span t("app.badges.aucun_disponible"), class: "badge badge-retard"
    end
  end

  # Un abonné n'a droit qu'à un livre : l'état est binaire, il n'y a pas
  # de compteur à afficher. Quand le livre déjà emprunté est en retard,
  # le badge le dit précisément plutôt que de rester sur la mention
  # générique "A déjà un livre" : c'est ce que la référence montre pour
  # Ibrahim Traoré, et c'est l'information la plus utile au comptoir.
  def badge_abonne(member)
    case member.borrow_block_reason
    when nil
      tag.span t("app.badges.peut_emprunter"), class: "badge badge-dispo"
    when :already_borrowing
      if member.current_loan&.overdue?
        tag.span t("app.badges.en_retard"), class: "badge badge-retard"
      else
        tag.span t("app.badges.deja_un_livre"), class: "badge badge-attention"
      end
    when :membership_expired then tag.span t("app.badges.a_reinscrire"), class: "badge badge-attention"
    when :suspended          then tag.span t("app.badges.suspendu"),     class: "badge badge-retard"
    end
  end

  # État d'un prêt en cours, du point de vue de l'échéance.
  def badge_echeance(loan)
    if loan.overdue?
      jours = loan.days_overdue
      tag.span t("app.badges.retard_de", n: jours, mot: pluriel(jours, singulier: "app.mots.jour.un", pluriel: "app.mots.jour.plusieurs")), class: "badge badge-retard"
    elsif loan.days_until_due <= 2
      jours = loan.days_until_due
      libelle = jours.zero? ? t("app.badges.a_rendre_aujourdhui") : t("app.badges.a_rendre_dans", n: jours, mot: pluriel(jours, singulier: "app.mots.jour.un", pluriel: "app.mots.jour.plusieurs"))
      tag.span libelle, class: "badge badge-attention"
    else
      tag.span t("app.badges.dans_les_delais"), class: "badge badge-dispo"
    end
  end

  def date_courte(date) = date && l(date, format: :long)

  # Statut de l'adhésion, indépendant du fait d'avoir ou non un emprunt en
  # cours : utilisé dans la liste et la fiche d'un abonné.
  def badge_adhesion(member)
    if member.suspended?
      tag.span t("app.badges.suspendu"), class: "badge badge-retard"
    elsif member.membership_expired?
      tag.span t("app.badges.expire_depuis", date: date_courte(member.expires_on)), class: "badge badge-retard"
    elsif member.membership_expiring_soon?
      jours = (member.expires_on - Date.current).to_i
      tag.span t("app.badges.expire_dans", n: jours, mot: pluriel(jours, singulier: "app.mots.jour.un", pluriel: "app.mots.jour.plusieurs")), class: "badge badge-attention"
    else
      tag.span t("app.badges.actif_jusquau", date: date_courte(member.expires_on)), class: "badge badge-dispo"
    end
  end

  # Badge d'une ligne de la liste des abonnés : un seul badge, le plus
  # utile en premier. Un prêt en retard prime sur tout le reste, c'est ce
  # qui demande le plus vite une action au comptoir.
  def badge_ligne_abonne(member)
    loan = member.current_loan

    if loan&.overdue?
      tag.span t("app.badges.jours_de_retard_court", n: loan.days_overdue), class: "badge badge-retard"
    elsif member.currently_suspended?
      tag.span t("app.badges.suspendu"), class: "badge badge-retard"
    elsif member.membership_expired?
      tag.span t("app.badges.adhesion_expiree"), class: "badge badge-attention"
    elsif loan
      tag.span t("app.badges.pret_en_cours"), class: "badge badge-neutre"
    elsif member.joined_on >= 3.days.ago.to_date
      tag.span t("app.badges.nouvelle_carte"), class: "badge badge-dispo"
    else
      tag.span t("app.badges.actif"), class: "badge badge-neutre"
    end
  end

  # Couleur du dos de livre sur l'étagère. Dérivée de l'identité de
  # l'ouvrage (jamais d'une valeur au hasard) : un même titre garde
  # toujours la même couleur d'un affichage à l'autre.
  DOS_LIVRE_COULEURS = %w[ #0A6B3C #B31942 #0A2240 #8A5200 #143A6B #6B4A0A ].freeze

  def couleur_dos(book) = DOS_LIVRE_COULEURS[book.id % DOS_LIVRE_COULEURS.size]

  # Vignette façon dos de livre : la vraie photo de couverture si le
  # responsable en a pris une, sinon un dos coloré avec le titre en tout
  # petit. Même gabarit dans les deux cas, pour ne rien décaler dans les
  # listes au fil des photos ajoutées.
  def dos_livre(book, grand: false)
    classe_photo = grand ? "dos-livre-photo dos-livre-grand" : "dos-livre-photo"
    classe_dos   = grand ? "dos-livre dos-livre-grand" : "dos-livre"

    if book.cover.attached?
      image_tag book.cover, class: classe_photo, alt: book.title
    else
      tag.div class: classe_dos, style: "background-color: #{couleur_dos(book)}" do
        tag.span book.title
      end
    end
  end

  # Lien d'appel direct. Sur le téléphone du bibliothécaire, un appui
  # compose le numéro : c'est tout l'intérêt d'afficher les retards.
  # Les numéros sont saisis au format local, l'indicatif du pays choisi à
  # l'inscription est ajouté ici (Côte d'Ivoire par défaut).
  def lien_telephone(member)
    return nil if member.phone.blank?

    "tel:#{member.phone_country_code}#{member.phone.gsub(/\D/, '')}"
  end
end
