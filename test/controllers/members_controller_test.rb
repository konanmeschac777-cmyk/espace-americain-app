require "test_helper"

# L'inscription et la réinscription. L'adhésion est gratuite : ces écrans
# n'enregistrent pas un paiement, ils enregistrent une autorisation — et le
# numéro de carte, qui est calculé et jamais saisi.
class MembersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "le fichier des abonnés n'est pas accessible sans être connecté" do
    sign_out

    get members_path
    assert_redirected_to new_session_path

    assert_no_difference -> { Member.count } do
      post members_path, params: { member: { full_name: "Awa Diabaté", card_number: "TSL-#{Date.current.year}-9999" } }
    end
  end

  # --- Inscription --------------------------------------------------------

  test "le formulaire propose le numéro de carte suivant" do
    get new_member_path

    assert_response :success
    assert_select "input[name=?][value=?]", "member[card_number]", Member.next_card_number
  end

  test "inscrire un abonné crée sa carte pour un an" do
    numero = Member.next_card_number

    assert_difference -> { Member.count }, 1 do
      post members_path, params: { member: {
        full_name: "Awa Diabaté", card_number: numero,
        phone: "07 08 12 44 90", phone_country_code: "+225",
        age: "19", neighborhood: "Tiassalé centre"
      } }
    end

    membre = Member.find_by!(card_number: numero)
    assert_equal "Awa", membre.first_name
    assert_equal "Diabaté", membre.last_name
    assert_equal Date.current, membre.joined_on
    assert_equal Date.current >> 12, membre.expires_on
    assert_equal sites(:tiassale), membre.site, "le MVP ne sert que Tiassalé"
    assert membre.can_borrow?

    assert_redirected_to tableau_de_bord_path
    assert_match numero, flash[:notice]
  end

  test "le dernier mot du nom saisi devient le nom de famille" do
    post members_path, params: { member: {
      full_name: "  Aya Marie   Koné  ", card_number: Member.next_card_number
    } }

    membre = Member.order(:id).last
    assert_equal "Aya Marie", membre.first_name
    assert_equal "Koné", membre.last_name, "c'est sur lui que la liste est triée"
  end

  test "un nom vide renvoie le formulaire sans rien créer" do
    assert_no_difference -> { Member.count } do
      post members_path, params: { member: { full_name: "", card_number: Member.next_card_number } }
    end

    assert_response :unprocessable_entity
  end

  test "un numéro pris entre-temps est remplacé par un numéro libre" do
    assert_no_difference -> { Member.count } do
      post members_path, params: { member: {
        full_name: "Awa Diabaté", card_number: members(:aya).card_number
      } }
    end

    assert_response :unprocessable_entity

    # Le bibliothécaire ne peut rien faire d'un numéro déjà pris : le
    # formulaire lui en propose un autre plutôt qu'une erreur à corriger.
    assert_select "input[name=?][value=?]", "member[card_number]", Member.next_card_number
  end

  # --- Profession ---------------------------------------------------------

  test "une profession de la liste est enregistrée par son identifiant" do
    post members_path, params: { member: {
      full_name: "Awa Diabaté", card_number: Member.next_card_number,
      profession: "enseignant"
    } }

    assert_equal "enseignant", Member.order(:id).last.profession,
      "c'est l'identifiant qui est stocké, pas le libellé traduit"
  end

  test "« Autre » enregistre le texte saisi à côté, jamais la sentinelle" do
    post members_path, params: { member: {
      full_name: "Awa Diabaté", card_number: Member.next_card_number,
      profession: Member::PROFESSION_AUTRE, profession_autre: "  Chauffeur de taxi  "
    } }

    assert_equal "Chauffeur de taxi", Member.order(:id).last.profession
  end

  # Le cas d'un navigateur où le JavaScript ne s'exécute pas : le champ
  # libre reste masqué et le menu envoie « autre » tout seul. Mieux vaut
  # une profession vide que cette valeur technique dans le fichier.
  test "« Autre » sans rien écrire à côté laisse la profession vide" do
    post members_path, params: { member: {
      full_name: "Awa Diabaté", card_number: Member.next_card_number,
      profession: Member::PROFESSION_AUTRE, profession_autre: "   "
    } }

    assert_nil Member.order(:id).last.profession
  end

  test "une profession hors liste rouvre le champ libre à la modification" do
    membre = members(:aya)
    membre.update!(profession: "Chauffeur de taxi")

    get edit_member_path(membre)

    assert_response :success
    assert_select "select[name=?] option[selected][value=?]", "member[profession]", Member::PROFESSION_AUTRE
    assert_select "input[name=?][value=?]", "member[profession_autre]", "Chauffeur de taxi"
    assert_select "div[data-profession-target=?][hidden]", "autre", 0,
      "le champ libre doit être ouvert, pas masqué, quand il porte déjà une valeur"
  end

  # Le champ libre part masqué côté serveur plutôt que d'être masqué par le
  # JavaScript après coup : sur les téléphones du comptoir, il apparaîtrait
  # puis disparaîtrait à chaque ouverture du formulaire.
  test "le champ libre part masqué sur un formulaire vierge" do
    get new_member_path

    assert_response :success
    assert_select "div[data-profession-target=?][hidden]", "autre", 1
  end

  # L'identifiant stocké ne veut rien dire pour le bibliothécaire : c'est
  # sur la fiche qu'il redevient un mot, et dans la langue de l'application.
  test "la fiche affiche le libellé traduit de la profession" do
    get member_path(members(:aya))

    assert_response :success
    assert_select "body", /Étudiant\(e\)/
    assert_select "body", { text: /etudiant/, count: 0 },
      "l'identifiant stocké ne doit jamais atteindre l'écran"
  end

  test "une profession hors liste s'affiche telle qu'elle a été écrite" do
    membre = members(:aya)
    membre.update!(profession: "Chauffeur de taxi")

    get member_path(membre)

    assert_select "body", /Chauffeur de taxi/
  end

  test "modifier une fiche enregistre la nouvelle profession" do
    membre = members(:aya)

    patch member_path(membre), params: { member: {
      full_name: "Aya Koné", phone: membre.phone, profession: "enseignant"
    } }

    assert_redirected_to member_path(membre)
    assert_equal "enseignant", membre.reload.profession
  end

  # Le formulaire de la fiche envoie toujours le menu « Profession ». Une
  # requête qui ne le porte pas ne parle pas de profession : l'effacer
  # reviendrait à perdre une saisie que personne n'a demandé de retirer.
  test "une modification sans le champ profession ne l'efface pas" do
    membre = members(:aya)

    patch member_path(membre), params: { member: { full_name: "Aya Koné", phone: "01 02 03 04 05" } }

    assert_equal "etudiant", membre.reload.profession
    assert_equal "01 02 03 04 05", membre.phone
  end

  # --- Réinscription ------------------------------------------------------

  test "réinscrire prolonge d'un an et affiche la nouvelle date" do
    membre = members(:adjoua)

    post renew_member_path(membre)

    assert_response :success
    assert_equal Date.current >> 12, membre.reload.expires_on
    assert membre.can_borrow?, "la réinscription doit rouvrir le droit d'emprunter"
  end

  test "réinscrire depuis un prêt bloqué ramène au prêt" do
    membre = members(:adjoua)

    post renew_member_path(membre, redirect_to_loan: "1")

    assert_redirected_to new_loan_path(member_id: membre.id)
    assert_match membre.full_name, flash[:notice]
  end

  # --- Suspension ---------------------------------------------------------

  test "suspendre un abonné lui interdit le prêt jusqu'à la levée" do
    membre = members(:aya)

    post suspend_member_path(membre)

    assert membre.reload.suspended?
    assert_equal :suspended, membre.borrow_block_reason
    assert_redirected_to member_path(membre)

    post lift_suspend_member_path(membre)

    assert_not membre.reload.suspended?
    assert membre.can_borrow?
  end

  # --- Fiche et modification ---------------------------------------------

  test "la fiche montre le prêt en cours et l'historique" do
    membre = members(:aya)
    pret_rendu(book: books(:orateur), member: membre, rendu_le: Date.current - 20)
    pret_en_cours(book: books(:organiser), member: membre, du_dans: 5)

    get member_path(membre)

    assert_response :success
    assert_select "body", /S'organiser pour réussir/
    assert_select "body", /Devenez un grand orateur/
  end

  test "modifier une fiche ne touche pas au numéro de la carte déjà remise" do
    membre = members(:aya)
    numero = membre.card_number

    patch member_path(membre), params: { member: {
      full_name: "Aya Koné", phone: "01 02 03 04 05",
      card_number: "TSL-#{Date.current.year}-0001"
    } }

    assert_redirected_to member_path(membre)
    assert_equal numero, membre.reload.card_number
    assert_equal "01 02 03 04 05", membre.phone
  end

  test "une modification invalide renvoie le formulaire" do
    membre = members(:aya)

    patch member_path(membre), params: { member: { full_name: "", phone: "07 00 00 00 00" } }

    assert_response :unprocessable_entity
    assert_equal "Koné", membre.reload.last_name
  end

  # --- Liste --------------------------------------------------------------

  test "chaque vue de la liste ne montre que les fiches qui la concernent" do
    pret_en_cours(book: books(:organiser), member: members(:kouadio), en_retard_de: 5)

    get members_path(filtre: "en_retard")
    assert_response :success
    assert_select "body", /N'Guessan/
    assert_select "body", { text: /Traoré/, count: 0 }

    get members_path(filtre: "a_reinscrire")
    assert_select "body", /Brou/
    assert_select "body", { text: /N'Guessan/, count: 0 }
  end

  test "la recherche retrouve un abonné par son nom" do
    get members_path(q: "Traoré")

    assert_response :success
    assert_select "body", /Ibrahim Traoré/
    assert_select "body", { text: /Aya Koné/, count: 0 }
  end

  test "les fiches à traiter restent visibles sous la vue complète" do
    get members_path(filtre: "tous")

    assert_response :success
    # Adjoua (expirée) et Ibrahim (suspendu) demandent une action.
    assert_select "body", /Brou/
    assert_select "body", /Traoré/
  end
end
