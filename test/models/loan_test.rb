require "test_helper"

# Le prêt est la pièce centrale : c'est lui qui décide de l'échéance, du
# retard et de ce qu'on a le droit de prolonger. Tout ce qui suit se
# vérifie sans attendre quatorze jours, en posant l'échéance à la main.
class LoanTest < ActiveSupport::TestCase
  setup do
    @book   = books(:organiser)
    @member = members(:aya)
  end

  # --- Ouverture du prêt --------------------------------------------------

  test "un prêt préparé aujourd'hui est dû dans le nombre de jours réglé" do
    loan = Loan.prepare(book: @book, member: @member)

    assert_equal Date.current, loan.borrowed_on
    assert_equal Date.current + 14, loan.due_on
    assert_equal 0, loan.renewals_count
    assert loan.valid?
    assert loan.new_record?, "prepare ne doit pas enregistrer : l'appelant vérifie d'abord l'éligibilité"
  end

  test "l'échéance suit le réglage et n'est pas un quatorze en dur" do
    Setting.find_by!(key: "loan_days").update!(value: "21")

    assert_equal Date.current + 21, Loan.prepare(book: @book, member: @member).due_on
  end

  test "une échéance antérieure à l'emprunt est refusée" do
    loan = Loan.new(book: @book, member: @member,
                    borrowed_on: Date.current, due_on: Date.current - 1)

    assert_not loan.valid?
    assert loan.errors[:due_on].any?
  end

  test "un prêt reste ouvert tant que rien n'est rendu" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 5)

    assert loan.open?
    assert_includes Loan.open, loan
    assert_not_includes Loan.returned, loan
  end

  # --- Retard -------------------------------------------------------------

  test "le retard se compte en jours depuis l'échéance" do
    loan = pret_en_cours(book: @book, member: @member, en_retard_de: 6)

    assert loan.overdue?
    assert_equal 6, loan.days_overdue
    assert_equal(-6, loan.days_until_due)
  end

  test "un prêt dû aujourd'hui n'est pas encore en retard" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 0)

    assert_not loan.overdue?
    assert_equal 0, loan.days_overdue
  end

  test "un oubli de plus d'un mois se distingue d'un simple retard" do
    oubli  = pret_en_cours(book: @book, member: @member, en_retard_de: 45)
    retard = pret_en_cours(book: books(:orateur), member: members(:kouadio), en_retard_de: 3)

    assert oubli.long_overdue?
    assert_not retard.long_overdue?
    assert_includes Loan.long_overdue, oubli
    assert_not_includes Loan.long_overdue, retard
  end

  test "les vues de la liste des emprunts trient chaque prêt dans une seule colonne" do
    en_retard = pret_en_cours(book: @book, member: @member, en_retard_de: 4)
    bientot   = pret_en_cours(book: books(:orateur), member: members(:kouadio), du_dans: 1)
    tranquille = pret_en_cours(book: books(:essentiel), member: members(:yao), du_dans: 10)

    assert_equal [ en_retard ], Loan.overdue.to_a
    assert_equal [ bientot ],   Loan.due_soon.to_a
    assert_equal [ tranquille ], Loan.on_time.to_a
    assert_equal 3, Loan.open.count
  end

  test "les retards les plus anciens passent devant : c'est l'ordre de relance" do
    recent = pret_en_cours(book: @book, member: @member, en_retard_de: 2)
    ancien = pret_en_cours(book: books(:orateur), member: members(:kouadio), en_retard_de: 30)

    assert_equal [ ancien, recent ], Loan.overdue.oldest_due_first.to_a
  end

  # --- Renouvellement -----------------------------------------------------

  test "renouveler repousse l'échéance de la durée réglée" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    echeance = loan.due_on

    assert loan.renew!
    assert_equal echeance + 14, loan.due_on
    assert_equal 1, loan.renewals_count
  end

  test "un prêt déjà en retard repart d'aujourd'hui, pas de l'ancienne échéance" do
    loan = pret_en_cours(book: @book, member: @member, en_retard_de: 10)

    assert loan.renew!
    assert_equal Date.current + 14, loan.due_on
    assert_not loan.overdue?, "renouveler un retard doit rendre du temps, pas prolonger le retard"
  end

  test "un prêt ne se renouvelle qu'une fois" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    loan.renew!

    assert_not loan.renewable?
    assert_not loan.renew!
    assert_equal 1, loan.renewals_count
  end

  test "le nombre de renouvellements suit le réglage" do
    Setting.find_by!(key: "max_renewals").update!(value: "2")
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)

    assert loan.renew!
    assert loan.renew!
    assert_not loan.renew!
  end

  test "un prêt rendu ne se renouvelle plus" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    loan.return!

    assert_not loan.renewable?
    assert_not loan.renew!
  end

  # --- Retour -------------------------------------------------------------

  test "rendre un livre ferme le prêt" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)

    assert loan.return!
    assert_not loan.open?
    assert_equal Date.current, loan.returned_on
    assert_includes Loan.returned, loan
    assert_not_includes Loan.open, loan
  end

  test "un livre déjà rendu ne se rend pas une deuxième fois" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    loan.return!(on: Date.current - 1)

    assert_not loan.return!
    assert_equal Date.current - 1, loan.returned_on, "la date du premier retour doit rester"
  end

  test "une fois rendu le retard n'existe plus, mais on sait qu'il a eu lieu" do
    loan = pret_en_cours(book: @book, member: @member, en_retard_de: 6)
    loan.return!

    assert_not loan.overdue?, "le livre est revenu : il n'est plus en retard"
    assert loan.returned_late?
    assert_equal 6, loan.days_late
  end

  test "un livre rendu à temps ne laisse aucun retard derrière lui" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 2)
    loan.return!

    assert_not loan.returned_late?
    assert_equal 0, loan.days_late
  end

  # --- Recherche au comptoir ---------------------------------------------

  test "la recherche de retour porte sur le livre comme sur l'abonné" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 5)

    assert_includes Loan.open.search("organiser"), loan
    assert_includes Loan.open.search("Koné"), loan
    assert_includes Loan.open.search("Aya"), loan
    assert_includes Loan.open.search(@member.card_number), loan
    assert_not_includes Loan.open.search("Cialdini"), loan
  end

  test "la recherche de retour ignore ce qui est déjà revenu sur l'étagère" do
    rendu = pret_rendu(book: @book, member: @member)

    assert_not_includes Loan.open.search("organiser"), rendu
  end

  test "une recherche vide ne filtre rien" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 5)

    assert_includes Loan.open.search(""), loan
    assert_includes Loan.open.search(nil), loan
  end
end
