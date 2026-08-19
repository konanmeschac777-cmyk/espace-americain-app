# Un prêt. Tant que returned_on est nul, le livre est dehors.
# C'est cette colonne, et elle seule, qui distingue un prêt en cours d'un
# prêt terminé : il n'y a pas de champ "statut" à tenir à jour.
class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :member

  validates :borrowed_on, :due_on, presence: true
  validates :renewals_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :due_after_borrowed

  scope :open,     -> { where(returned_on: nil) }
  scope :returned, -> { where.not(returned_on: nil) }
  scope :overdue,  -> { open.where(due_on: ...Date.current) }
  scope :due_within, ->(days) { open.where(due_on: Date.current..days.days.from_now.to_date) }
  # Les retards les plus anciens en tête : c'est l'ordre de relance.
  scope :oldest_due_first, -> { order(:due_on) }

  # Ouvre un prêt aux conditions du jour, sans l'enregistrer.
  # Les vérifications d'éligibilité restent du ressort de l'appelant.
  def self.prepare(book:, member:, on: Date.current)
    new(
      book: book,
      member: member,
      borrowed_on: on,
      due_on: on + Setting.loan_days,
      renewals_count: 0
    )
  end

  def open?     = returned_on.nil?
  def overdue?  = open? && due_on < Date.current

  def days_overdue
    overdue? ? (Date.current - due_on).to_i : 0
  end

  def days_until_due
    open? ? (due_on - Date.current).to_i : nil
  end

  def renewable?
    open? && renewals_count < Setting.max_renewals
  end

  # Prolonge le prêt. Si le livre est déjà en retard, la nouvelle échéance
  # part d'aujourd'hui et non de l'ancienne date, sinon le renouvellement
  # rendrait le livre immédiatement en retard.
  def renew!
    return false unless renewable?

    starting_point = [ due_on, Date.current ].max
    update!(due_on: starting_point + Setting.loan_days, renewals_count: renewals_count + 1)
  end

  def return!(on: Date.current)
    return false unless open?

    update!(returned_on: on)
  end

  private

  def due_after_borrowed
    return if due_on.blank? || borrowed_on.blank?

    errors.add(:due_on, "doit être après la date d'emprunt") if due_on < borrowed_on
  end
end
