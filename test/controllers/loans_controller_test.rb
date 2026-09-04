require "test_helper"

# Le geste le plus fréquent du comptoir : enregistrer un prêt. Ces tests
# suivent l'écran de bout en bout — les trois étapes, les quatre motifs de
# blocage, et le renouvellement.
class LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @member = members(:aya)
    @book   = books(:organiser)
  end

  test "le comptoir n'est pas accessible sans être connecté" do
    sign_out

    get new_loan_path
    assert_redirected_to new_session_path

    assert_no_difference -> { Loan.count } do
      post loans_path, params: { member_id: @member.id, book_id: @book.id }
    end
  end

  # --- Les trois étapes de l'écran ---------------------------------------

  test "l'étape en cours se lit dans l'URL, pas dans une session" do
    # Première étape : chercher l'abonné.
    get new_loan_path(member_q: "Koné")
    assert_response :success
    assert_select "body", /Koné/

    # Deuxième étape : l'abonné est choisi, on cherche l'ouvrage.
    get new_loan_path(member_id: @member.id, book_q: "organiser")
    assert_response :success
    assert_select "body", /S'organiser pour réussir/

    # Troisième étape : les deux sont désignés, il ne reste qu'à confirmer.
    get new_loan_path(member_id: @member.id, book_id: @book.id)
    assert_response :success
  end

  test "la recherche d'ouvrage ne propose pas un titre archivé" do
    get new_loan_path(member_id: @member.id, book_q: "retiré")

    assert_response :success
    assert_select "body", { text: /Un titre retiré du fonds/, count: 0 },
                  "un titre archivé n'est plus sur l'étagère"
  end

  # --- Enregistrement -----------------------------------------------------

  test "enregistrer un prêt le crée aux conditions du jour" do
    assert_difference -> { Loan.count }, 1 do
      post loans_path, params: { member_id: @member.id, book_id: @book.id }
    end

    loan = Loan.last
    assert_equal @member, loan.member
    assert_equal @book, loan.book
    assert_equal Date.current, loan.borrowed_on
    assert_equal Date.current + 14, loan.due_on
    assert_redirected_to new_loan_path(confirmed_loan_id: loan.id)
  end

  test "l'écran de succès prend toute la place après l'enregistrement" do
    post loans_path, params: { member_id: @member.id, book_id: @book.id }
    follow_redirect!

    assert_response :success
    assert_select "body", /S'organiser pour réussir/
  end

  # --- Les quatre motifs de blocage --------------------------------------

  test "un abonné suspendu ne repart pas avec un livre" do
    assert_no_difference -> { Loan.count } do
      post loans_path, params: { member_id: members(:ibrahim).id, book_id: @book.id }
    end

    assert_redirected_to new_loan_path(member_id: members(:ibrahim).id, book_id: @book.id)
    assert_equal I18n.t("app.flash.blocage_suspendu"), flash[:alert]
  end

  test "une adhésion expirée doit être prolongée avant tout prêt" do
    assert_no_difference -> { Loan.count } do
      post loans_path, params: { member_id: members(:adjoua).id, book_id: @book.id }
    end

    assert_equal I18n.t("app.flash.blocage_adhesion_expiree"), flash[:alert]
  end

  test "un abonné qui a déjà un livre n'en prend pas un second" do
    pret_en_cours(book: books(:orateur), member: @member, du_dans: 5)

    assert_no_difference -> { Loan.count } do
      post loans_path, params: { member_id: @member.id, book_id: @book.id }
    end

    assert_equal I18n.t("app.flash.blocage_deja_un_livre"), flash[:alert]
  end

  test "un titre dont tous les exemplaires sont sortis est refusé" do
    pret_en_cours(book: books(:orateur), member: members(:kouadio), du_dans: 5)

    assert_no_difference -> { Loan.count } do
      post loans_path, params: { member_id: @member.id, book_id: books(:orateur).id }
    end

    assert_equal I18n.t("app.flash.blocage_aucun_exemplaire"), flash[:alert]
  end

  test "une suspension arrivée à son terme ne bloque plus rien" do
    assert_difference -> { Loan.count }, 1 do
      post loans_path, params: { member_id: members(:yao).id, book_id: @book.id }
    end
  end

  # --- Renouvellement -----------------------------------------------------

  test "prolonger un prêt repousse son échéance de quatorze jours" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    echeance = loan.due_on

    post renew_loan_path(loan)

    assert_equal echeance + 14, loan.reload.due_on
    assert_equal 1, loan.renewals_count
    assert_redirected_to loans_path
    assert_match "S'organiser pour réussir", flash[:notice]
  end

  test "un deuxième renouvellement est refusé avec une explication" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    loan.renew!
    echeance = loan.due_on

    post renew_loan_path(loan)

    assert_equal echeance, loan.reload.due_on
    assert_equal I18n.t("app.flash.pret_deja_renouvele"), flash[:alert]
  end

  # --- Liste des emprunts -------------------------------------------------

  test "chaque vue de la liste ne montre que les prêts qui la concernent" do
    pret_en_cours(book: @book, member: @member, en_retard_de: 5)
    pret_en_cours(book: books(:orateur), member: members(:kouadio), du_dans: 1)

    get loans_path(filtre: "retard")
    assert_response :success
    assert_select "details.ligne-details", 1
    assert_select "body", /S'organiser pour réussir/

    get loans_path(filtre: "bientot")
    assert_select "details.ligne-details", 1
    assert_select "body", /Devenez un grand orateur/

    get loans_path(filtre: "tous")
    assert_select "details.ligne-details", 2
  end

  test "un filtre inconnu dans l'URL retombe sur la liste complète" do
    pret_en_cours(book: @book, member: @member, du_dans: 5)

    get loans_path(filtre: "n-importe-quoi")

    assert_response :success
    assert_select "details.ligne-details", 1
  end

  test "un prêt rendu quitte la liste des emprunts" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 5)
    loan.return!

    get loans_path(filtre: "tous")

    assert_select "details.ligne-details", 0
  end
end
