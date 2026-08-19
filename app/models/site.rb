# Une antenne du réseau American Spaces. Seul Tiassalé est actif au MVP.
class Site < ApplicationRecord
  has_many :books,   dependent: :restrict_with_error
  has_many :members, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(active: true) }

  def to_s = name
end
