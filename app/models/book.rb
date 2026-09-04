# Un titre du fonds, en un ou plusieurs exemplaires.
#
# La disponibilité n'est pas stockée : elle se calcule en retirant les prêts
# en cours du nombre total d'exemplaires. Un compteur en base finirait par
# mentir dès le premier incident.
class Book < ApplicationRecord
  belongs_to :site
  belongs_to :category
  has_many :loans, dependent: :restrict_with_error

  # Les prêts en cours, en association à part pour que les listes puissent
  # les précharger. Sans elle, afficher soixante titres demandait soixante
  # et une requêtes : une pour la liste, puis une par ligne pour compter
  # ce qui est sorti. Sur le poste de l'Espace, ça se sent.
  has_many :open_loans, -> { open }, class_name: "Loan", inverse_of: :book

  has_one_attached :cover

  validates :title, presence: true, uniqueness: { scope: :site_id, message: proc { I18n.t("app.flash.titre_deja_existant") } }
  validates :language, presence: true
  validates :total_copies, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate  :assez_d_exemplaires_pour_les_prets_en_cours

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

  # .size et non .count : quand la liste a préchargé l'association, le
  # compte se lit en mémoire sans requête ; sinon Rails fait le COUNT.
  def copies_on_loan   = open_loans.size
  def copies_available = total_copies - copies_on_loan
  def available?       = copies_available.positive?

  # Nul quand l'auteur n'a pas encore été relevé sur la couverture.
  # Les vues décident quoi afficher à la place, le modèle n'invente rien.
  def author_display = author.presence

  def needs_completion? = author.blank? || !author_confirmed?

  # Date de retour la plus proche, pour un titre entièrement sorti.
  def next_return_date = loans.open.minimum(:due_on)

  def to_s = title

  private

  # Le nombre d'exemplaires ne peut pas descendre sous ce qui est déjà
  # sorti. Le bibliothécaire recompte l'étagère, corrige cinq en deux
  # alors que trois sont dehors, et la disponibilité devient négative :
  # l'écran de prêt affichait alors « -1/2 ». Mieux vaut refuser et dire
  # pourquoi, puisque le chiffre saisi est de toute façon faux — les
  # exemplaires dehors font partie du fonds, ils ne sont pas sur
  # l'étagère au moment du comptage.
  def assez_d_exemplaires_pour_les_prets_en_cours
    return if total_copies.blank? || new_record?

    # loans.open.count et non copies_on_loan : ce dernier passe par
    # l'association préchargée des listes, qui peut avoir été chargée avant
    # qu'un prêt ne soit enregistré et répondrait alors un compte périmé.
    # Ici on décide d'accepter ou de refuser une saisie : il faut le
    # chiffre de la base, pas celui de la mémoire.
    sortis = loans.open.count
    return if total_copies >= sortis

    errors.add(:total_copies, :trop_peu_pour_les_prets, count: sortis)
  end
end
