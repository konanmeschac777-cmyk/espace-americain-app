require "application_system_test_case"

# Le parcours d'une journée au comptoir, dans un vrai navigateur.
#
# Ce test ne vérifie aucune règle métier — les modèles s'en chargent. Il
# vérifie ce qu'eux ne voient pas : que l'application se construit et
# s'affiche, que la connexion mène au tableau de bord, et que les écrans
# du comptoir s'atteignent les uns depuis les autres.
class ComptoirTest < ApplicationSystemTestCase
  setup do
    @bibliothecaire = users(:one)
  end

  test "la couverture s'affiche avant toute connexion" do
    visit root_path

    assert_text I18n.t("app.accueil.titre")
    # Le fonds annoncé sur la couverture vient de la base, pas d'un chiffre
    # écrit en dur : c'est le premier signe que l'application est vivante.
    assert_text Book.active.sum(:total_copies).to_s
  end

  test "le bibliothécaire se connecte et arrive au tableau de bord" do
    se_connecter(@bibliothecaire)

    assert_current_path tableau_de_bord_path
    assert_text I18n.t("app.tableau_de_bord.bonjour", initiales: @bibliothecaire.initials)
  end

  test "un mot de passe faux ne laisse pas entrer" do
    se_connecter(@bibliothecaire, mot_de_passe: "ce-n-est-pas-le-bon")

    assert_current_path new_session_path
    assert_no_current_path tableau_de_bord_path
  end

  test "depuis le tableau de bord, les écrans du comptoir s'atteignent" do
    se_connecter(@bibliothecaire)

    click_on I18n.t("app.tableau_de_bord.preter")
    assert_current_path new_loan_path

    visit tableau_de_bord_path
    click_on I18n.t("app.tableau_de_bord.voir_rapport")
    assert_current_path rapport_du_mois_path
  end
end
