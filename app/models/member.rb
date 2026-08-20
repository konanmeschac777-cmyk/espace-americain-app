# Un abonné. L'adhésion est gratuite et vaut un an.
#
# L'expiration ne sert donc pas à faire payer, mais à savoir qui fréquente
# encore l'Espace : une carte d'un an oblige à repasser au comptoir, ce qui
# tient la liste à jour. La réinscription est un simple geste d'autorisation.
class Member < ApplicationRecord
  belongs_to :site
  has_many :loans, dependent: :restrict_with_error

  EXPIRING_SOON_DAYS = 30

  validates :card_number, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :joined_on, :expires_on, presence: true

  scope :suspended,     -> { where(suspended: true) }
  scope :expired,       -> { where(expires_on: ...Date.current) }
  scope :expiring_soon, -> { where(expires_on: Date.current..EXPIRING_SOON_DAYS.days.from_now.to_date) }
  scope :by_name,       -> { order(:last_name, :first_name) }

  scope :search, ->(term) {
    next all if term.blank?

    pattern = "%#{term.to_s.strip}%"
    where("last_name LIKE :q OR first_name LIKE :q OR card_number LIKE :q", q: pattern)
  }

  # Numéro de carte suivant, au format TSL-2026-0087.
  #
  # Il est calculé et non saisi : au comptoir, faire recopier un numéro à la
  # main produit des doublons et des fautes de frappe, et le doublon ne se
  # voit qu'une fois la carte remise.
  #
  # Le compteur repart à 1 chaque année : l'année fait partie du numéro, il
  # n'y a donc pas de collision entre 2026 et 2027.
  def self.next_card_number(on: Date.current)
    prefix  = "#{Setting.card_prefix}-#{on.year}-"
    dernier = where("card_number LIKE ?", "#{prefix}%").maximum(:card_number)
    suivant = dernier ? dernier.split("-").last.to_i + 1 : 1

    format("%s%04d", prefix, suivant)
  end

  def full_name = "#{first_name} #{last_name}"

  # Un abonné n'a droit qu'à un livre à la fois : ce prêt-là, ou aucun.
  def current_loan = loans.open.first

  def membership_expired? = expires_on < Date.current

  def membership_expiring_soon?
    !membership_expired? && expires_on <= EXPIRING_SOON_DAYS.days.from_now.to_date
  end

  def can_borrow? = borrow_block_reason.nil?

  # Renvoie le motif qui interdit l'emprunt, ou nil si la voie est libre.
  # L'écran de prêt affiche un bandeau différent pour chaque motif, c'est
  # pourquoi on retourne la raison et pas un simple faux.
  def borrow_block_reason
    return :suspended         if suspended?
    return :membership_expired if membership_expired?
    return :already_borrowing  if loans.open.count >= Setting.loan_quota

    nil
  end

  # Prolonge d'un an. Si l'adhésion est déjà expirée, l'année repart
  # d'aujourd'hui plutôt que de la date dépassée : sinon une carte oubliée
  # pendant deux ans repartirait déjà expirée.
  def renew_membership!
    starting_point = [ expires_on, Date.current ].max
    update!(expires_on: starting_point >> Setting.membership_months)
  end

  def to_s = full_name
end
