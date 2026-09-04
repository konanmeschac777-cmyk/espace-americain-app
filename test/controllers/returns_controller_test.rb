require "test_helper"

# Le retour est le geste où se décide une suspension : un livre rendu en
# retard bloque l'abonné pour autant de jours qu'il en a pris. C'est la
# règle la plus lourde de conséquences du comptoir, et le bibliothécaire
# peut la lever sur place quand la raison est bonne.
class ReturnsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @member = members(:aya)
    @book   = books(:organiser)
  end

  test "l'écran de retour n'est pas accessible sans être connecté" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)
    sign_out

    get new_return_path
    assert_redirected_to new_session_path

    post returns_path, params: { loan_id: loan.id }
    assert loan.reload.open?, "aucun retour ne doit être enregistré sans session"
  end

  # --- Retrouver le prêt --------------------------------------------------

  test "une recherche qui ne désigne qu'un prêt affiche directement l'aperçu" do
    pret_en_cours(book: @book, member: @member, du_dans: 3)

    get new_return_path(q: "organiser")

    assert_response :success
    assert_select "p.titre-ouvrage", /S'organiser pour réussir/
  end

  test "une recherche qui en désigne plusieurs propose la liste" do
    pret_en_cours(book: @book, member: @member, du_dans: 3)
    pret_en_cours(book: @book, member: members(:kouadio), du_dans: 6)

    get new_return_path(q: "organiser")

    assert_response :success
    assert_select "a.ligne-liste", 2
  end

  test "la recherche ne remonte pas les livres restés sur l'étagère" do
    get new_return_path(q: "organiser")

    assert_response :success
    assert_select "p.titre-ouvrage", 0
    assert_select "div.etat-vide"
  end

  test "un prêt désigné par son identifiant s'affiche sans recherche" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)

    get new_return_path(loan_id: loan.id)

    assert_response :success
    assert_select "p.titre-ouvrage", /S'organiser pour réussir/
  end

  # --- Enregistrer le retour ---------------------------------------------

  test "rendre un livre à temps le referme et ne suspend personne" do
    loan = pret_en_cours(book: @book, member: @member, du_dans: 3)

    post returns_path, params: { loan_id: loan.id }

    assert_not loan.reload.open?
    assert_equal Date.current, loan.returned_on
    assert_nil @member.reload.suspended_until
    assert @member.can_borrow?, "le livre est rendu : l'abonné peut en reprendre un"

    assert_redirected_to tableau_de_bord_path
    assert_match "S'organiser pour réussir", flash[:notice]
    assert_match @member.full_name, flash[:notice]
  end

  test "un retour en retard suspend l'abonné pour autant de jours que le retard" do
    loan = pret_en_cours(book: @book, member: @member, en_retard_de: 6)

    post returns_path, params: { loan_id: loan.id }

    assert_equal 6, loan.reload.days_late
    assert_equal Date.current + 6, @member.reload.suspended_until
    assert_equal :suspended, @member.borrow_block_reason
  end

  test "le bibliothécaire peut lever la suspension au moment du retour" do
    loan = pret_en_cours(book: @book, member: @member, en_retard_de: 6)

    post returns_path, params: { loan_id: loan.id, waive_suspension: "1" }

    assert_nil @member.reload.suspended_until
    assert @member.can_borrow?
  end

  test "lever la suspension au retour n'efface pas celle décidée au comptoir" do
    membre = members(:ibrahim)
    loan = pret_en_cours(book: @book, member: membre, en_retard_de: 4)

    post returns_path, params: { loan_id: loan.id, waive_suspension: "1" }

    assert membre.reload.suspended?, "la décision du responsable se lève à la fiche, pas ici"
    assert_equal :suspended, membre.borrow_block_reason
  end

  test "une suspension déjà en cours est remplacée par celle du nouveau retard" do
    membre = members(:fatou) # suspendu jusque dans 3 jours
    loan = pret_en_cours(book: @book, member: membre, en_retard_de: 10)

    post returns_path, params: { loan_id: loan.id }

    assert_equal Date.current + 10, membre.reload.suspended_until
  end

  test "un livre déjà rendu ne se rend pas une deuxième fois" do
    loan = pret_en_cours(book: @book, member: @member, en_retard_de: 6)
    loan.return!(on: Date.current - 1)

    post returns_path, params: { loan_id: loan.id }

    assert_equal Date.current - 1, loan.reload.returned_on
    assert_nil @member.reload.suspended_until, "un doublon ne doit pas poser de suspension"
    assert_redirected_to new_return_path
    assert_equal I18n.t("app.flash.livre_deja_rendu"), flash[:alert]
  end

  test "le retour remet l'exemplaire à disposition" do
    loan = pret_en_cours(book: books(:orateur), member: @member, du_dans: 3)
    assert_not books(:orateur).available?

    post returns_path, params: { loan_id: loan.id }

    assert books(:orateur).reload.available?
  end
end
