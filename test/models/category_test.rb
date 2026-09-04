require "test_helper"

# La cote est l'adresse du livre sur l'étagère. Sans elle, chacun range à
# sa logique et le fonds se mélange en quelques semaines.
class CategoryTest < ActiveSupport::TestCase
  test "le préfixe de cote vient des trois premières lettres du slug" do
    assert_equal "COM", categories(:communication).shelf_prefix
    assert_equal "PRO", categories(:productivite).shelf_prefix
  end

  test "la cote proposée suit le nombre de titres déjà rangés" do
    categorie = categories(:productivite)

    # essentiel et organiser sont actifs dans cette catégorie.
    assert_equal "PRO-03", categorie.next_shelf_mark
  end

  test "un titre archivé ne prend plus de place sur l'étagère" do
    categorie = categories(:communication)
    avant = categorie.next_shelf_mark

    books(:influence).update!(active: false)

    assert_not_equal avant, categorie.next_shelf_mark
    assert_equal "COM-02", categorie.next_shelf_mark
  end

  test "une catégorie qui contient des ouvrages ne se supprime pas" do
    assert_not categories(:communication).destroy
  end
end
