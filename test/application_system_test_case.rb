require "test_helper"

# Les tests système ouvrent un vrai navigateur, sans fenêtre. Ils vérifient
# ce que les tests de contrôleur ne peuvent pas voir : que les feuilles de
# style se construisent, que le JavaScript du comptoir répond, et qu'un
# écran mène bien au suivant.
#
# Ils sont lents — quelques secondes chacun contre quelques millisecondes.
# On n'y met donc que les parcours complets, pas les règles métier : celles-ci
# sont déjà tenues par les tests de modèle.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Le comptoir se tient sur un téléphone. Les écrans sont dessinés pour
  # cette largeur, et c'est dans cette largeur qu'il faut les vérifier :
  # le menu et le tiroir ne se comportent pas pareil en grand.
  def au_comptoir
    page.driver.browser.manage.window.resize_to(390, 844)
    yield
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  # Connecte un bibliothécaire en passant par le vrai formulaire : c'est le
  # premier écran de la journée, il mérite d'être traversé pour de bon.
  def se_connecter(user, mot_de_passe: "password")
    visit new_session_path
    fill_in I18n.t("app.connexion.email"), with: user.email_address
    fill_in I18n.t("app.connexion.mot_de_passe"), with: mot_de_passe
    click_on I18n.t("app.connexion.connecter")
  end
end
