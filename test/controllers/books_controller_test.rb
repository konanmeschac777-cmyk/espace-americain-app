require "test_helper"

# Le catalogue. Le fonds a été importé d'un fichier qui ne contenait que
# titres et quantités : une bonne partie des fiches se complète après coup,
# d'où la file « à compléter » qui enchaîne les fiches sans repasser par la
# liste.
class BooksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "le catalogue n'est pas accessible sans être connecté" do
    sign_out

    get books_path
    assert_redirected_to new_session_path

    assert_no_difference -> { Book.count } do
      post books_path, params: { book: { title: "Un ajout clandestin", category_id: categories(:communication).id, total_copies: 1, language: "fr" } }
    end
  end

  # --- Ajouter un ouvrage -------------------------------------------------

  test "ajouter un ouvrage lui donne sa cote de rangement" do
    assert_difference -> { Book.count }, 1 do
      post books_path, params: { book: {
        title: "L'art de la négociation", author: "Chris Voss",
        category_id: categories(:communication).id,
        language: "fr", total_copies: 2, collection: "Nouveaux Horizons"
      } }
    end

    livre = Book.find_by!(title: "L'art de la négociation")
    assert_equal "COM-03", livre.shelf_mark, "deux titres actifs en communication : le nouveau prend le suivant"
    assert_equal sites(:tiassale), livre.site
    assert livre.active?
    assert_redirected_to new_book_path(confirmed_book_id: livre.id)
  end

  test "un auteur saisi au comptoir est un auteur confirmé" do
    post books_path, params: { book: {
      title: "Négocier sans céder", author: "Roger Fisher",
      category_id: categories(:communication).id, language: "fr", total_copies: 1
    } }

    livre = Book.find_by!(title: "Négocier sans céder")
    assert livre.author_confirmed?
    assert_not livre.needs_completion?
  end

  test "un ouvrage ajouté sans auteur part dans la file à compléter" do
    post books_path, params: { book: {
      title: "Un titre sans auteur connu", category_id: categories(:productivite).id,
      language: "fr", total_copies: 1
    } }

    livre = Book.find_by!(title: "Un titre sans auteur connu")
    assert_not livre.author_confirmed?
    assert_includes Book.needing_completion, livre
  end

  test "un titre déjà présent dans le fonds est refusé" do
    assert_no_difference -> { Book.count } do
      post books_path, params: { book: {
        title: books(:orateur).title, category_id: categories(:communication).id,
        language: "fr", total_copies: 1
      } }
    end

    assert_response :unprocessable_entity
  end

  test "un titre vide renvoie le formulaire" do
    assert_no_difference -> { Book.count } do
      post books_path, params: { book: { title: "", category_id: categories(:communication).id, total_copies: 1, language: "fr" } }
    end

    assert_response :unprocessable_entity
  end

  # --- Compléter les fiches ----------------------------------------------

  test "la file à compléter enchaîne les fiches sans repasser par la liste" do
    a_completer = books(:essentiel)

    get edit_book_path(a_completer, completer: true)
    assert_response :success

    patch book_path(a_completer, completer: true), params: { book: {
      title: a_completer.title, author: "Gary Keller",
      category_id: a_completer.category_id, language: "fr", total_copies: 2
    } }

    assert a_completer.reload.author_confirmed?
    assert_equal "Gary Keller", a_completer.author
    assert_redirected_to edit_book_path(books(:influence), completer: true)
    assert_match "1 fiche restante", flash[:notice]
  end

  test "la dernière fiche complétée ramène au catalogue" do
    books(:essentiel).update!(author: "Gary Keller", author_confirmed: true)
    derniere = books(:influence)

    patch book_path(derniere, completer: true), params: { book: {
      title: derniere.title, author: "Robert Cialdini",
      category_id: derniere.category_id, language: "fr", total_copies: 1
    } }

    assert_redirected_to books_path
    assert_equal 0, Book.active.needing_completion.count
  end

  test "hors mode file, enregistrer une fiche ramène simplement au catalogue" do
    livre = books(:organiser)

    patch book_path(livre), params: { book: {
      title: livre.title, author: "David Allen",
      category_id: livre.category_id, language: "fr", total_copies: 5
    } }

    assert_redirected_to books_path
    assert_equal 5, livre.reload.total_copies
  end

  test "une modification invalide renvoie le formulaire" do
    livre = books(:organiser)

    patch book_path(livre), params: { book: {
      title: "", category_id: livre.category_id, language: "fr", total_copies: 1
    } }

    assert_response :unprocessable_entity
    assert_equal "S'organiser pour réussir", livre.reload.title
  end

  # --- Archiver -----------------------------------------------------------

  test "archiver retire l'ouvrage du catalogue sans effacer son histoire" do
    livre = books(:organiser)
    pret_rendu(book: livre, member: members(:aya), rendu_le: Date.current - 10)

    post archive_book_path(livre)

    assert_not livre.reload.active?
    assert_equal 1, livre.loans.count, "l'historique de prêts doit rester consultable"
    assert_redirected_to books_path
    assert_match livre.title, flash[:notice]

    get books_path
    assert_select "body", { text: /S'organiser pour réussir/, count: 0 }
  end

  # --- Consulter ----------------------------------------------------------

  test "le catalogue montre le fonds et compte ce qui reste à compléter" do
    get books_path

    assert_response :success
    assert_select "body", /Devenez un grand orateur/
    assert_select "body", { text: /Un titre retiré du fonds/, count: 0 }
  end

  test "on filtre le catalogue par catégorie" do
    get books_path(categorie: "productivite")

    assert_response :success
    assert_select "body", /S'organiser pour réussir/
    assert_select "body", { text: /Devenez un grand orateur/, count: 0 }
  end

  test "la file à compléter ne montre que les fiches incomplètes" do
    get books_path(categorie: "completer")

    assert_response :success
    assert_select "body", /The One Thing/
    assert_select "body", /Influence et manipulation/
    assert_select "body", { text: /S'organiser pour réussir/, count: 0 }
  end

  test "la recherche porte sur le titre et sur l'auteur" do
    get books_path(q: "Allen")

    assert_response :success
    assert_select "body", /S'organiser pour réussir/
    assert_select "body", { text: /Devenez un grand orateur/, count: 0 }
  end

  test "la fiche d'un ouvrage précède sa modification" do
    livre = books(:orateur)

    get book_path(livre)

    assert_response :success
    assert_select "body", /Devenez un grand orateur/
    assert_select "a[href=?]", edit_book_path(livre)
  end
end
