# Les six catégories sont calées sur le fonds réel, qui est du développement
# professionnel. Pas de littérature ni de jeunesse : aucun livre concerné.
class Category < ApplicationRecord
  has_many :books, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  # Préfixe de cote, dérivé du slug : "communication" donne COM.
  # Les six catégories donnent six préfixes distincts. En ajouter une qui
  # commence par les trois mêmes lettres qu'une existante créerait une
  # ambiguïté de rangement : la tâche catalogue:coter le détecte.
  def shelf_prefix = slug.first(3).upcase

  def to_s = name
end
