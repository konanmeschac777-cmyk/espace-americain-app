# Les six catégories sont calées sur le fonds réel, qui est du développement
# professionnel. Pas de littérature ni de jeunesse : aucun livre concerné.
class Category < ApplicationRecord
  has_many :books, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  def to_s = name
end
