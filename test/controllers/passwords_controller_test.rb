require "test_helper"

# L'écran « mot de passe oublié ». Il a deux visages selon l'endroit où
# l'application tourne : en ligne, il envoie un lien par e-mail ; sur le
# serveur local de l'Espace, qui n'a pas d'internet, il affiche la commande
# à passer sur le poste. Les deux sont couverts ici.
class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  # --- En ligne : le lien par e-mail --------------------------------------

  test "l'écran propose le formulaire" do
    get new_password_path

    assert_response :success
    assert_select "input[type=submit]"
  end

  test "demander un lien l'envoie et confirme à l'écran" do
    assert_emails 1 do
      post passwords_path, params: { email_address: @user.email_address }
    end

    # Pas de redirection : la confirmation remplace le formulaire sur le
    # même écran, avec l'adresse visée sous les yeux pour repérer une faute
    # de frappe sans avoir à tout recommencer.
    assert_response :success
    assert_texte I18n.t("app.mot_de_passe.lien_envoye_titre")
    assert_texte @user.email_address
  end

  # La réponse doit être la même que l'adresse existe ou non, sinon l'écran
  # dirait à quiconque l'ouvre quels comptes existent.
  test "une adresse inconnue reçoit la même réponse, sans e-mail" do
    assert_emails 0 do
      post passwords_path, params: { email_address: "inconnu@example.com" }
    end

    assert_response :success
    assert_texte I18n.t("app.mot_de_passe.lien_envoye_titre")
  end

  # --- Le lien reçu -------------------------------------------------------

  test "le lien mène au choix du nouveau mot de passe" do
    get edit_password_path(@user.password_reset_token)

    assert_response :success
  end

  test "un lien trafiqué ou périmé ramène au début" do
    get edit_password_path("jeton-invalide")

    assert_redirected_to new_password_path
    follow_redirect!
    assert_bandeau "lien_invalide"
  end

  test "choisir un nouveau mot de passe le change et renvoie à la connexion" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token),
          params: { password: "motdepasse", password_confirmation: "motdepasse" }
    end

    assert_redirected_to new_session_path
    follow_redirect!
    assert_bandeau "mot_de_passe_modifie"
  end

  # Un mot de passe se change souvent parce qu'un téléphone a été perdu :
  # les sessions déjà ouvertes doivent tomber avec lui, sinon l'appareil
  # perdu reste connecté.
  test "changer le mot de passe ferme les sessions déjà ouvertes" do
    @user.sessions.create!

    assert_changes -> { @user.sessions.count }, to: 0 do
      put password_path(@user.password_reset_token),
          params: { password: "motdepasse", password_confirmation: "motdepasse" }
    end
  end

  test "deux mots de passe différents ne changent rien" do
    jeton = @user.password_reset_token

    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(jeton),
          params: { password: "celui-ci", password_confirmation: "celui-la" }
    end

    assert_redirected_to edit_password_path(jeton)
    follow_redirect!
    assert_bandeau "mots_de_passe_ne_correspondent_pas"
  end

  # --- Serveur local de l'Espace, sans internet ---------------------------

  # Sans internet, aucun e-mail ne part. L'écran doit le dire au lieu de
  # faire remplir un formulaire pour rien.
  test "hors ligne, l'écran donne la commande au lieu d'un formulaire" do
    en_mode_hors_ligne do
      get new_password_path

      assert_response :success
      assert_select "input[type=submit]", false, "aucun formulaire ne doit être proposé hors ligne"
      assert_select "p", /bibliothecaire:creer/
    end
  end

  # La réponse doit être la même que l'adresse existe ou non : sinon l'écran
  # dirait à quiconque est sur le Wi-Fi de l'Espace quels comptes existent.
  test "hors ligne, la réponse ne révèle pas quels comptes existent" do
    en_mode_hors_ligne do
      post passwords_path, params: { email_address: @user.email_address }
      assert_response :success
      assert_select "p", /bibliothecaire:creer/

      post passwords_path, params: { email_address: "inconnu@example.com" }
      assert_response :success
      assert_select "p", /bibliothecaire:creer/

      assert_enqueued_emails 0
    end
  end

  private
    # Le bandeau tel qu'il s'affiche après une redirection : c'est la phrase
    # que le bibliothécaire lit, pas seulement une clé posée dans le flash.
    def assert_bandeau(cle)
      assert_select "p.bandeau", I18n.t("app.flash.#{cle}")
    end

    # Les écrans sont traduits : viser le texte français en dur ferait
    # échouer la suite le jour où la locale par défaut change.
    def assert_texte(texte)
      assert_select "body", /#{Regexp.escape(texte)}/
    end

    def en_mode_hors_ligne
      precedent = Rails.configuration.x.offline_server
      Rails.configuration.x.offline_server = true
      yield
    ensure
      Rails.configuration.x.offline_server = precedent
    end
end
