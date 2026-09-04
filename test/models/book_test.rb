require "test_helper"

# La disponibilité d'un titre n'est pas stockée : elle se recalcule à
# chaque fois depuis les prêts en cours. Ces tests vérifient que ce calcul
# suit bien les prêts, dans les deux sens.
class BookTest < ActiveSupport::TestCase
  test "un titre sans prêt en cours est disponible en totalité" do
    livre = books(:organiser)

    assert_equal 3, livre.copies_available
    assert livre.available?
  end

  test "chaque prêt retire un exemplaire du rayon" do
    livre = books(:organiser)
    pret_en_cours(book: livre, member: members(:aya), du_dans: 5)
    pret_en_cours(book: livre, member: members(:kouadio), du_dans: 5)

    assert_equal 2, livre.copies_on_loan
    assert_equal 1, livre.copies_available
    assert livre.available?
  end

  test "un titre en un seul exemplaire devient indisponible dès le premier prêt" do
    livre = books(:orateur)
    pret_en_cours(book: livre, member: members(:aya), du_dans: 5)

    assert_equal 0, livre.copies_available
    assert_not livre.available?
  end

  test "le retour remet l'exemplaire en rayon" do
    livre = books(:orateur)
    loan = pret_en_cours(book: livre, member: members(:aya), du_dans: 5)

    loan.return!

    assert livre.available?
    assert_equal 1, livre.copies_available
  end

  test "un titre entièrement sorti annonce la première date de retour" do
    livre = books(:organiser)
    pret_en_cours(book: livre, member: members(:aya), du_dans: 9)
    pret_en_cours(book: livre, member: members(:kouadio), du_dans: 2)
    pret_en_cours(book: livre, member: members(:yao), du_dans: 6)

    assert_not livre.available?
    assert_equal Date.current + 2, livre.next_return_date
  end

  # --- File « à compléter » ----------------------------------------------

  test "une fiche sans auteur est à compléter" do
    livre = books(:essentiel)

    assert livre.needs_completion?
    assert_nil livre.author_display
    assert_includes Book.needing_completion, livre
  end

  test "un auteur relevé mais pas vérifié reste à compléter" do
    livre = books(:influence)

    assert livre.needs_completion?
    assert_equal "R. Cialdini", livre.author_display
    assert_includes Book.author_to_confirm, livre
    assert_includes Book.needing_completion, livre
  end

  test "une fiche complète sort de la file" do
    livre = books(:organiser)

    assert_not livre.needs_completion?
    assert_not_includes Book.needing_completion, livre
  end

  # --- Catalogue ----------------------------------------------------------

  test "un titre archivé quitte le catalogue sans quitter la base" do
    archive = books(:retire)

    assert_not_includes Book.active, archive
    assert_includes Book.all, archive
  end

  test "on retrouve un titre par son intitulé ou son auteur" do
    livre = books(:organiser)

    assert_includes Book.search("organiser"), livre
    assert_includes Book.search("Allen"), livre
    assert_not_includes Book.search("orateur"), livre
  end

  test "le même titre ne peut pas être saisi deux fois dans la même antenne" do
    doublon = Book.new(site: sites(:tiassale), category: categories(:communication),
                       title: books(:orateur).title, language: "fr", total_copies: 1)

    assert_not doublon.valid?
    assert doublon.errors[:title].any?
  end

  test "une autre antenne peut avoir le même titre dans son fonds" do
    ailleurs = Book.new(site: sites(:abidjan), category: categories(:communication),
                        title: books(:orateur).title, language: "fr", total_copies: 1)

    assert ailleurs.valid?
  end

  test "un fonds ne descend pas en dessous d'un exemplaire" do
    livre = books(:organiser)

    livre.total_copies = 0
    assert_not livre.valid?

    livre.total_copies = 1
    assert livre.valid?
  end

  test "un ouvrage déjà emprunté ne se supprime pas" do
    livre = books(:organiser)
    pret_rendu(book: livre, member: members(:aya))

    assert_not livre.destroy, "l'archivage existe pour ça : l'historique doit rester lisible"
  end

  # --- Le recomptage de l'étagère -----------------------------------------
  #
  # Le bibliothécaire recompte les exemplaires en rayon et corrige la
  # fiche. Les exemplaires sortis ne sont pas sur l'étagère : les oublier
  # rendait la disponibilité négative, et l'écran de prêt affichait « -1/2 ».

  test "le nombre d'exemplaires ne descend pas sous les prêts en cours" do
    livre = books(:orateur)
    livre.update!(total_copies: 5)
    pret_en_cours(book: livre, member: members(:aya), du_dans: 7)
    pret_en_cours(book: livre, member: members(:kouadio), du_dans: 7)

    livre.total_copies = 1

    assert_not livre.valid?
    assert livre.errors[:total_copies].any?
  end

  test "le nombre d'exemplaires peut descendre jusqu'aux prêts en cours" do
    livre = books(:orateur)
    livre.update!(total_copies: 5)
    pret_en_cours(book: livre, member: members(:aya), du_dans: 7)

    livre.total_copies = 1

    assert livre.valid?, "un seul exemplaire sorti, un seul déclaré : c'est cohérent"
    assert_equal 0, livre.copies_available
  end

  test "la disponibilité ne peut plus devenir négative" do
    livre = books(:orateur)
    livre.update!(total_copies: 3)
    3.times { |i| pret_en_cours(book: livre, member: Member.by_name.offset(i).first, du_dans: 7) }

    livre.total_copies = 1

    assert_not livre.save
    assert_operator livre.reload.copies_available, :>=, 0
  end
end
