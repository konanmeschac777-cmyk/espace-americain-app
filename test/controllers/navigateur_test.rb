require "test_helper"

# Le seuil de navigateur décide si le comptoir peut travailler.
#
# Sur le serveur de l'Espace, qui n'a pas internet, les navigateurs des
# téléphones ne se mettront jamais à jour : un seuil relevé par mégarde —
# en repassant au préréglage :modern de Rails, par exemple — rendrait
# l'application inutilisable sans que personne ne puisse y remédier sur
# place. Ces tests fixent la limite pour qu'elle ne bouge pas sans qu'on
# le décide.
class NavigateurTest < ActionDispatch::IntegrationTest
  CHROME  = "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%s.0.0.0 Mobile Safari/537.36"
  SAFARI  = "Mozilla/5.0 (iPhone; CPU iPhone OS like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%s Mobile Safari/604.1"

  test "les navigateurs du printemps 2023 sont acceptés" do
    # Le plancher réel du projet : @layer pour la feuille de style,
    # les import maps pour le JavaScript, color-mix pour les couleurs.
    visite_avec CHROME % "111"
    assert_response :success

    visite_avec SAFARI % "16.4"
    assert_response :success
  end

  test "les navigateurs plus anciens sont refusés" do
    visite_avec CHROME % "110"
    assert_response :not_acceptable

    visite_avec SAFARI % "16.3"
    assert_response :not_acceptable
  end

  # Le préréglage :modern de Rails exigeait Chrome 120, pour des
  # fonctionnalités (webp, push, badges) que ce projet n'utilise pas.
  test "un Chrome de 2023 n'est plus refusé pour rien" do
    visite_avec CHROME % "115"

    assert_response :success
  end

  # Refuser sans expliquer laisserait le bibliothécaire devant une page
  # anglaise de Rails, sans savoir quoi faire.
  test "le refus s'explique en français et dit quoi faire" do
    visite_avec CHROME % "80"

    assert_response :not_acceptable
    assert_match "Ce navigateur est trop ancien", response.body
    assert_match "Que faire", response.body
    # La page s'affiche sur le navigateur qu'elle refuse : elle ne peut
    # dépendre d'aucun fichier extérieur, que le serveur hors ligne ne
    # servirait pas non plus.
    assert_no_match(/<link[^>]+stylesheet/, response.body)
    # La règle @layer elle-même, pas le mot : le commentaire de la page
    # explique justement qu'elle s'en passe.
    assert_no_match(/@layer[\w\s,]*\{/, response.body)
  end

  private

  def visite_avec(user_agent)
    get root_path, headers: { "HTTP_USER_AGENT" => user_agent }
  end
end
