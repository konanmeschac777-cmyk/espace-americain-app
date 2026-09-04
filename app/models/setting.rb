# Réglages métier modifiables sans redéployer : durée du prêt, nombre de
# renouvellements, quota de livres par abonné, durée de l'abonnement.
#
# Les modèles lisent ces valeurs plutôt que de les coder en dur, pour que le
# bibliothécaire puisse passer le prêt de 14 à 21 jours sans toucher au code.
class Setting < ApplicationRecord
  # Les réglages que l'écran des réglages laisse modifier, avec leurs
  # bornes. Cette liste fait deux choses : elle empêche d'écrire une clé
  # inventée depuis le navigateur, et elle refuse les valeurs qui
  # casseraient le comptoir — un prêt de zéro jour rendrait tout livre en
  # retard le jour même, un quota de zéro interdirait tout emprunt.
  #
  # Les bornes hautes ne sont pas des limites techniques mais des garde-fous
  # contre la faute de frappe : 140 jours au lieu de 14 se voit au moment de
  # la saisie, pas trois semaines plus tard sur les relances.
  REGLAGES = {
    "loan_days"         => { min: 1, max: 90 },
    "max_renewals"      => { min: 0, max: 5 },
    "loan_quota"        => { min: 1, max: 10 },
    "membership_months" => { min: 1, max: 60 },
    "card_prefix"       => { format: /\A[A-Z]{2,5}\z/ }
  }.freeze

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  validate :valeur_acceptable

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

  # Les cinq réglages de l'écran, dans l'ordre d'affichage, créés au besoin.
  # Un réglage absent de la base (base neuve, ou supprimé à la main) doit
  # apparaître à l'écran avec sa valeur par défaut plutôt que de manquer.
  def self.modifiables
    REGLAGES.keys.map do |key|
      find_by(key: key) || new(key: key, value: defaut(key).to_s)
    end
  end

  # Enregistre les valeurs saisies. Tout passe ou rien : une seule valeur
  # refusée laisse les autres inchangées, sinon le comptoir se retrouverait
  # avec une moitié de réglages appliquée sans que personne ne le sache.
  #
  # Renvoie les réglages, porteurs de leurs erreurs quand il y en a.
  def self.enregistrer(valeurs)
    reglages = REGLAGES.keys.map do |key|
      reglage = find_or_initialize_by(key: key)
      reglage.value = valeurs[key].to_s.strip if valeurs.key?(key)
      reglage
    end

    transaction do
      raise ActiveRecord::Rollback unless reglages.all?(&:valid?)

      reglages.each(&:save!)
    end

    reglages
  end

  # Valeur d'origine d'un réglage, celle de db/seeds.rb. Sert à remplir
  # l'écran quand la base n'a pas encore la ligne.
  def self.defaut(key)
    case key
    when "loan_days"         then 14
    when "max_renewals"      then 1
    when "loan_quota"        then 1
    when "membership_months" then 12
    when "card_prefix"       then "TSL"
    end
  end

  def entier? = REGLAGES.dig(key, :min).present?

  private

  def valeur_acceptable
    regle = REGLAGES[key]
    # Un réglage hors de cette liste est technique : rien à vérifier, mais
    # rien ne l'écrit non plus depuis l'écran.
    return if regle.nil? || value.blank?

    if regle[:format]
      errors.add(:value, :invalid) unless value.match?(regle[:format])
      return
    end

    # to_i transformerait "quatorze" en 0 : on refuse ce qui n'est pas
    # écrit en chiffres avant de comparer aux bornes.
    unless value.match?(/\A\d+\z/)
      errors.add(:value, :not_a_number)
      return
    end

    nombre = value.to_i
    errors.add(:value, :inclusion) unless nombre.between?(regle[:min], regle[:max])
  end
end
