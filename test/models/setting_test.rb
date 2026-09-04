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
end
