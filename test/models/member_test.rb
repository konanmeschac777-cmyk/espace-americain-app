require "test_helper"

# L'abonné décide de ce qui est possible au comptoir : qui peut emprunter,
# qui doit repasser se réinscrire, qui est suspendu et jusqu'à quand.
class MemberTest < ActiveSupport::TestCase
  # --- Numéro de carte ----------------------------------------------------

  test "le numéro de carte suit la dernière carte de l'année" do
    # Les fixtures montent jusqu'à 0233.
    assert_equal "TSL-#{Date.current.year}-0234", Member.next_card_number
  end

  test "le compteur repart à 1 l'année suivante" do
    travel_to Date.current.next_year do
      assert_equal "TSL-#{Date.current.year}-0001", Member.next_card_number
    end
  end

  test "le préfixe de la carte vient du réglage" do
    Setting.find_by!(key: "card_prefix").update!(value: "ABO")

    assert Member.next_card_number.start_with?("ABO-#{Date.current.year}-")
  end

  # --- Ce qui bloque un prêt ----------------------------------------------

  test "un abonné à jour et sans livre peut emprunter" do
    assert members(:aya).can_borrow?
    assert_nil members(:aya).borrow_block_reason
  end

  test "une adhésion expirée bloque le prêt" do
    assert_equal :membership_expired, members(:adjoua).borrow_block_reason
  end

  test "une suspension décidée au comptoir bloque le prêt sans date de fin" do
    assert_equal :suspended, members(:ibrahim).borrow_block_reason
  end

  test "une suspension posée par un retard bloque jusqu'à son terme" do
    assert_equal :suspended, members(:fatou).borrow_block_reason
  end

  test "une suspension arrivée à son terme se lève d'elle-même" do
    assert members(:yao).can_borrow?, "la date est passée : plus rien ne doit bloquer"
  end

  test "le dernier jour de suspension compte encore" do
    membre = members(:aya)
    membre.update!(suspended_until: Date.current)

    assert membre.currently_suspended?
  end

  test "un abonné qui a déjà un livre ne peut pas en prendre un second" do
    membre = members(:aya)
    pret_en_cours(book: books(:organiser), member: membre, du_dans: 5)

    assert_equal :already_borrowing, membre.borrow_block_reason
  end

  test "le quota suit le réglage" do
    Setting.find_by!(key: "loan_quota").update!(value: "2")
    membre = members(:aya)
    pret_en_cours(book: books(:organiser), member: membre, du_dans: 5)

    assert membre.can_borrow?

    pret_en_cours(book: books(:orateur), member: membre, du_dans: 5)
    assert_equal :already_borrowing, membre.borrow_block_reason
  end

  test "rendre le livre rouvre le droit d'emprunter" do
    membre = members(:aya)
    loan = pret_en_cours(book: books(:organiser), member: membre, du_dans: 5)
    loan.return!

    assert membre.can_borrow?
    assert_nil membre.current_loan
  end

  test "la suspension passe devant l'adhésion expirée" do
    membre = members(:adjoua)
    membre.suspend!

    assert_equal :suspended, membre.borrow_block_reason,
                 "c'est la suspension qu'il faut annoncer au comptoir, pas la réinscription"
  end

  # --- Lever une suspension -----------------------------------------------

  test "lever la suspension d'un retard n'efface pas une suspension du comptoir" do
    membre = members(:ibrahim)
    membre.update!(suspended_until: 5.days.from_now.to_date)

    membre.lift_suspension!

    assert_nil membre.suspended_until
    assert membre.suspended?, "la décision du responsable ne se lève pas depuis l'écran de retour"
    assert membre.currently_suspended?
  end

  test "lever la suspension du comptoir ne touche pas à celle d'un retard" do
    membre = members(:fatou)
    membre.update!(suspended: true)

    membre.unsuspend!

    assert_not membre.suspended?
    assert membre.currently_suspended?, "le retard court toujours"
  end

  # --- Adhésion -----------------------------------------------------------

  test "réinscrire prolonge d'un an à partir de la date d'expiration" do
    membre = members(:aya)
    echeance = membre.expires_on

    membre.renew_membership!

    assert_equal echeance >> 12, membre.expires_on
  end

  test "une carte oubliée depuis longtemps repart d'aujourd'hui" do
    membre = members(:adjoua)

    membre.renew_membership!

    assert_equal Date.current >> 12, membre.expires_on
    assert_not membre.membership_expired?, "une réinscription ne doit pas repartir déjà expirée"
  end

  test "la durée d'adhésion suit le réglage" do
    Setting.find_by!(key: "membership_months").update!(value: "6")
    membre = members(:adjoua)

    membre.renew_membership!

    assert_equal Date.current >> 6, membre.expires_on
  end

  test "une adhésion qui se termine dans le mois est signalée avant d'expirer" do
    assert members(:yao).membership_expiring_soon?, "expire dans 18 jours"
    assert_not members(:aya).membership_expiring_soon?, "expire dans 7 mois"
    assert_not members(:adjoua).membership_expiring_soon?, "déjà expirée : ce n'est plus un avertissement"
  end

  test "les fiches à traiter se retrouvent par leur état" do
    assert_includes Member.expired, members(:adjoua)
    assert_not_includes Member.expired, members(:aya)

    assert_includes Member.expiring_soon, members(:yao)
    assert_includes Member.suspended, members(:ibrahim)
    assert_not_includes Member.suspended, members(:fatou),
                        "une suspension automatique n'est pas une décision du comptoir"
  end

  # --- Recherche et affichage --------------------------------------------

  test "on retrouve un abonné par son nom, son prénom ou sa carte" do
    membre = members(:aya)

    assert_includes Member.search("Koné"), membre
    assert_includes Member.search("aya"), membre
    assert_includes Member.search(membre.card_number), membre
    assert_not_includes Member.search("Traoré"), membre
  end

  test "le nom complet garde l'ordre prénom puis nom" do
    assert_equal "Aya Koné", members(:aya).full_name
  end

  test "un âge négatif est refusé, un âge absent est accepté" do
    membre = members(:aya)

    membre.age = 0
    assert_not membre.valid?

    membre.age = nil
    assert membre.valid?, "l'âge n'est pas obligatoire : il n'est pas toujours demandé au comptoir"
  end

  test "deux abonnés ne peuvent pas porter le même numéro de carte" do
    doublon = Member.new(site: sites(:tiassale), card_number: members(:aya).card_number,
                         first_name: "Awa", last_name: "Diabaté",
                         joined_on: Date.current, expires_on: Date.current >> 12)

    assert_not doublon.valid?
    assert doublon.errors[:card_number].any?
  end

  test "un abonné qui a déjà emprunté ne se supprime pas" do
    membre = members(:aya)
    pret_rendu(book: books(:organiser), member: membre)

    assert_not membre.destroy, "l'historique des prêts doit rester consultable"
  end
end
