require "test_helper"

# Le tableau de bord et le rapport du mois ne sont pas des écrans de saisie :
# ce sont des chiffres. Le premier dit ce qu'il y a à faire aujourd'hui, le
# second est présenté au réseau American Spaces — une erreur de calcul y
# passerait inaperçue longtemps.
class PagesControllerTest < ActionDispatch::IntegrationTest
  test "la couverture s'affiche sans être connecté" do
    get root_path

    assert_response :success
  end

  test "un bibliothécaire déjà connecté arrive directement au comptoir" do
    sign_in_as(users(:one))

    get root_path

    assert_redirected_to tableau_de_bord_path
  end

  test "le tableau de bord n'est pas accessible sans être connecté" do
    get tableau_de_bord_path

    assert_redirected_to new_session_path
  end

  # --- Tableau de bord ----------------------------------------------------

  test "le tableau de bord compte les prêts en cours et les retards" do
    sign_in_as(users(:one))
    pret_en_cours(book: books(:organiser), member: members(:aya), en_retard_de: 5)
    pret_en_cours(book: books(:orateur), member: members(:kouadio), du_dans: 4)
    pret_rendu(book: books(:essentiel), member: members(:yao))

    get tableau_de_bord_path

    assert_response :success
    # Le livre déjà rendu ne compte plus parmi les prêts en cours.
    assert_select "p.text-navy", text: "2", count: 1
    assert_select "p", text: "1", count: 1, message: "un seul retard"
  end

  test "le tableau de bord met en avant ce qui rentre dans la semaine" do
    sign_in_as(users(:one))
    pret_en_cours(book: books(:organiser), member: members(:aya), en_retard_de: 3)
    pret_en_cours(book: books(:orateur), member: members(:kouadio), du_dans: 30)

    get tableau_de_bord_path

    assert_select "body", /S'organiser pour réussir/
    assert_select "body", { text: /Devenez un grand orateur/, count: 0 },
                  "un prêt dû dans un mois n'a rien à faire dans les relances du jour"
  end

  # --- Rapport du mois ----------------------------------------------------

  test "le rapport compte les prêts et les inscriptions du mois en cours" do
    sign_in_as(users(:one))
    debut = Date.current.beginning_of_month

    pret_en_cours(book: books(:organiser), member: members(:aya), borrowed_on: debut, du_dans: 3)
    pret_en_cours(book: books(:orateur), member: members(:kouadio), borrowed_on: debut + 1, du_dans: 5)
    # Le mois dernier : hors du rapport.
    pret_rendu(book: books(:essentiel), member: members(:yao), rendu_le: debut - 5)

    get rapport_du_mois_path

    assert_response :success
    assert_select "p.text-navy", text: "2", count: 1, message: "deux prêts enregistrés ce mois-ci"
  end

  test "le rapport se demande pour un mois précis" do
    sign_in_as(users(:one))
    mois_dernier = Date.current.beginning_of_month - 1.month
    emprunte_le = mois_dernier + 10

    Loan.create!(book: books(:organiser), member: members(:aya),
                 borrowed_on: emprunte_le, due_on: emprunte_le + 14,
                 returned_on: emprunte_le + 12)

    get rapport_du_mois_path(mois: mois_dernier.strftime("%Y-%m"))
    assert_response :success
    assert_select "p.text-navy", text: "1", count: 1, message: "le prêt du mois demandé"

    get rapport_du_mois_path
    assert_select "p.text-navy", text: "0", count: 1, message: "rien ce mois-ci"
  end

  test "un mois mal formé dans l'URL ne casse pas l'écran" do
    sign_in_as(users(:one))

    get rapport_du_mois_path(mois: "pas-une-date")

    assert_response :success
  end

  test "sans prêt du tout, le rapport le dit au lieu d'afficher un graphique vide" do
    sign_in_as(users(:one))

    get rapport_du_mois_path

    assert_response :success
    assert_select "div.etat-vide"
  end
end
