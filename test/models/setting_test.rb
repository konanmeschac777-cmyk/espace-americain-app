require "test_helper"

# Les règles du prêt sont en base pour que le responsable puisse passer le
# prêt de 14 à 21 jours sans toucher au code. Le repli existe pour le cas
# où un réglage aurait disparu de la table : le comptoir doit continuer de
# fonctionner, pas s'arrêter sur une erreur.
class SettingTest < ActiveSupport::TestCase
  test "les réglages se lisent dans la table" do
    assert_equal 14, Setting.loan_days
    assert_equal 1,  Setting.max_renewals
    assert_equal 1,  Setting.loan_quota
    assert_equal 12, Setting.membership_months
    assert_equal "TSL", Setting.card_prefix
  end

  test "une modification est prise en compte sans redémarrage" do
    Setting.find_by!(key: "loan_days").update!(value: "21")

    assert_equal 21, Setting.loan_days
  end

  test "un réglage disparu retombe sur sa valeur de secours" do
    Setting.where(key: %w[loan_days max_renewals loan_quota membership_months card_prefix]).delete_all

    assert_equal 14, Setting.loan_days
    assert_equal 1,  Setting.max_renewals
    assert_equal 1,  Setting.loan_quota
    assert_equal 12, Setting.membership_months
    assert_equal "TSL", Setting.card_prefix
  end

  test "deux réglages ne peuvent pas porter la même clé" do
    doublon = Setting.new(key: "loan_days", value: "30")

    assert_not doublon.valid?
  end

  # --- Les bornes ---------------------------------------------------------
  #
  # Depuis que l'écran des réglages existe, ces valeurs se saisissent au
  # comptoir. Une valeur absurde n'y casserait rien de visible tout de
  # suite : elle se verrait des semaines plus tard, sur les échéances.

  test "un prêt de zéro jour est refusé" do
    reglage = Setting.find_by!(key: "loan_days")

    assert_not reglage.update(value: "0")
    assert_equal 14, Setting.loan_days
  end

  test "une durée écrite en toutes lettres est refusée" do
    reglage = Setting.find_by!(key: "loan_days")

    # to_i transformerait « quatorze » en 0 sans rien dire.
    assert_not reglage.update(value: "quatorze")
  end

  test "une durée au-delà de la borne haute est refusée" do
    reglage = Setting.find_by!(key: "loan_days")

    # 140 au lieu de 14 : la faute de frappe qui ne se voit pas.
    assert_not reglage.update(value: "140")
  end

  test "zéro renouvellement est accepté, c'est une règle légitime" do
    reglage = Setting.find_by!(key: "max_renewals")

    assert reglage.update(value: "0")
    assert_equal 0, Setting.max_renewals
  end

  test "un préfixe de carte reste en lettres majuscules" do
    reglage = Setting.find_by!(key: "card_prefix")

    assert reglage.update(value: "TIA")
    assert_not reglage.update(value: "T5")
    assert_not reglage.update(value: "tsl")
    assert_not reglage.update(value: "TIASSALE")
  end

  # --- L'enregistrement d'ensemble ----------------------------------------

  test "enregistrer applique toutes les valeurs d'un coup" do
    Setting.enregistrer("loan_days" => "21", "loan_quota" => "3")

    assert_equal 21, Setting.loan_days
    assert_equal 3,  Setting.loan_quota
  end

  test "une seule valeur refusée laisse toutes les autres inchangées" do
    reglages = Setting.enregistrer("loan_days" => "21", "loan_quota" => "0")

    assert reglages.any? { |reglage| reglage.errors.any? }
    # Sans le tout ou rien, le comptoir se retrouverait avec la nouvelle
    # durée de prêt et l'ancien quota, sans que personne ne le sache.
    assert_equal 14, Setting.loan_days
    assert_equal 1,  Setting.loan_quota
  end

  test "modifiables propose les cinq réglages même sur une base vide" do
    Setting.delete_all

    reglages = Setting.modifiables

    assert_equal Setting::REGLAGES.keys, reglages.map(&:key)
    assert_equal "14", reglages.find { |r| r.key == "loan_days" }.value
  end
end
