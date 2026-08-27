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

  # Cote qu'aurait le prochain titre ajouté à cette catégorie, en aperçu.
  # La tâche catalogue:coter reste la seule à renuméroter tout le rayon :
  # ceci ne fait qu'ajouter à la suite, sans jamais retoucher les cotes
  # déjà attribuées.
  def next_shelf_mark
    format("%s-%02d", shelf_prefix, books.active.count + 1)
  end

  def to_s = name
end
