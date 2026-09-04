require "test_helper"

# L'écran des règles du comptoir. Ce sont les valeurs qui décident de tout
# le reste — durée d'un prêt, quota, adhésion — et elles se saisissent
# maintenant au comptoir plutôt qu'en console sur le poste serveur.
class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "l'écran affiche les cinq règles avec leurs valeurs" do
    get reglages_path

    assert_response :success
    assert_select "input[name=?][value=?]", "reglages[loan_days]", "14"
    assert_select "input[name=?][value=?]", "reglages[card_prefix]", "TSL"
  end

  test "les règles ne sont pas consultables sans être connecté" do
    sign_out

    get reglages_path

    assert_redirected_to new_session_path
  end

  test "changer la durée d'un prêt vaut pour les emprunts suivants" do
    patch reglages_path, params: { reglages: { loan_days: "21" } }

    assert_redirected_to reglages_path
    assert_equal 21, Setting.loan_days

    # Le prêt suivant part sur la nouvelle durée, sans redémarrage.
    pret = Loan.prepare(book: books(:orateur), member: members(:aya))
    assert_equal Date.current + 21, pret.due_on
  end

  test "une valeur refusée réaffiche l'écran avec le motif" do
    patch reglages_path, params: { reglages: { loan_days: "0" } }

    assert_response :unprocessable_entity
    assert_select "li", I18n.t("app.reglages.loan_days.erreur")
    assert_equal 14, Setting.loan_days
  end

  # Le tout ou rien vient du modèle, mais c'est ici qu'il compte : le
  # bibliothécaire remplit le formulaire d'un bloc et le valide d'un geste.
  test "une seule valeur fautive n'enregistre rien du tout" do
    patch reglages_path, params: { reglages: { loan_days: "21", loan_quota: "0" } }

    assert_response :unprocessable_entity
    assert_equal 14, Setting.loan_days
    assert_equal 1,  Setting.loan_quota
  end

  test "les prêts déjà enregistrés gardent leur échéance" do
    pret = pret_en_cours(book: books(:orateur), member: members(:aya), du_dans: 3)
    echeance = pret.due_on

    patch reglages_path, params: { reglages: { loan_days: "30" } }

    assert_equal echeance, pret.reload.due_on
  end

  # Une clé inventée dans la requête ne doit pas pouvoir créer une ligne
  # dans la table des réglages.
  test "une clé inconnue est ignorée" do
    assert_no_difference -> { Setting.where(key: "loan_free").count } do
      patch reglages_path, params: { reglages: { loan_free: "true" } }
    end
  end
end
