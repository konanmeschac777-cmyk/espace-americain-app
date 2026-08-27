# Un titre du fonds, en un ou plusieurs exemplaires.
#
# La disponibilité n'est pas stockée : elle se calcule en retirant les prêts
# en cours du nombre total d'exemplaires. Un compteur en base finirait par
# mentir dès le premier incident.
class Book < ApplicationRecord
  belongs_to :site
  belongs_to :category
  has_many :loans, dependent: :restrict_with_error
  has_one_attached :cover

  validates :title, presence: true, uniqueness: { scope: :site_id, message: proc { I18n.t("app.flash.titre_deja_existant") } }
  validates :language, presence: true
  validates :total_copies, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :active,   -> { where(active: true) }
  scope :by_title, -> { order(:title) }

  # Le catalogue vient d'un fichier qui ne contenait que titres et quantités.
  # Ces trois vues alimentent la file de travail "À compléter".
  scope :without_author,     -> { where(author: nil) }
  scope :author_to_confirm,  -> { where(author_confirmed: false).where.not(author: nil) }
  scope :needing_completion, -> { where(author: nil).or(where(author_confirmed: false)) }

  scope :search, ->(term) {
    next all if term.blank?

    pattern = "%#{term.to_s.strip}%"
    where("title LIKE :q OR author LIKE :q", q: pattern)
  }

  def copies_on_loan   = loans.open.count
  def copies_available = total_copies - copies_on_loan
  def available?       = copies_available.positive?

  # Nul quand l'auteur n'a pas encore été relevé sur la couverture.
  # Les vues décident quoi afficher à la place, le modèle n'invente rien.
  def author_display = author.presence

  def needs_completion? = author.blank? || !author_confirmed?

  # Date de retour la plus proche, pour un titre entièrement sorti.
  def next_return_date = loans.open.minimum(:due_on)

  def to_s = title
end
