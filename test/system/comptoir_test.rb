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

  # Le bouton « Enregistrer » vit dans la barre flottante du bas, donc en
  # dehors du formulaire : c'est l'attribut form="..." qui les relie. Un
  # test de contrôleur ne verrait pas cette liaison se rompre.
  test "les règles du comptoir se changent depuis l'écran" do
    se_connecter(@bibliothecaire)
    # Sans cette attente, « visit » partirait avant que la connexion n'ait
    # abouti et l'écran suivant renverrait au formulaire.
    assert_current_path tableau_de_bord_path

    visit parametres_path
    fill_in "reglages[loan_days]", with: "21"
    click_on I18n.t("app.admin.enregistrer")

    assert_text I18n.t("app.flash.reglages_enregistres")
    assert_equal 21, Setting.loan_days
  end

  test "depuis le tableau de bord, les écrans du comptoir s'atteignent" do
    se_connecter(@bibliothecaire)

    click_on I18n.t("app.tableau_de_bord.preter")
    assert_current_path new_loan_path

    visit tableau_de_bord_path
    click_on I18n.t("app.tableau_de_bord.voir_rapport")
    assert_current_path rapport_du_mois_path
  end

  # Le champ libre de « Profession » n'existe à l'écran que si le
  # JavaScript répond : c'est lui qui le sort de son état masqué sur le
  # choix « Autre ». Un test de contrôleur voit l'attribut hidden dans la
  # page, pas le fait qu'il se lève au bon moment.
  test "choisir « Autre » ouvre le champ libre de la profession" do
    se_connecter(@bibliothecaire)
    assert_current_path tableau_de_bord_path

    visit new_member_path
    champ_libre = "input[name='member[profession_autre]']"

    assert_no_selector champ_libre, visible: true

    select I18n.t("app.abonnes.profession_autre"), from: "member[profession]"
    assert_selector champ_libre, visible: true

    select I18n.t("app.professions.enseignant"), from: "member[profession]"
    assert_no_selector champ_libre, visible: true
  end
end
