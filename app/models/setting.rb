# Réglages métier modifiables sans redéployer : durée du prêt, nombre de
# renouvellements, quota de livres par abonné, durée de l'abonnement.
#
# Les modèles lisent ces valeurs plutôt que de les coder en dur, pour que le
# bibliothécaire puisse passer le prêt de 14 à 21 jours sans toucher au code.
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  # Setting.value_for("loan_days") => "14"
  def self.value_for(key)
    find_by(key: key)&.value
  end

  # Le second argument sert de filet si le réglage a été supprimé en base.
  def self.integer_for(key, fallback)
    value_for(key)&.to_i || fallback
  end

  def self.loan_days         = integer_for("loan_days", 14)
  def self.max_renewals      = integer_for("max_renewals", 1)
  def self.loan_quota        = integer_for("loan_quota", 1)
  def self.membership_months = integer_for("membership_months", 12)
  def self.card_prefix       = value_for("card_prefix") || "TSL"
end
