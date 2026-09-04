# db/seeds.rb
#
# Données de départ de l'American Shelf de Tiassalé.
#
# Idempotent : ce fichier peut être relancé sans créer de doublons.
#   bin/rails db:seed
#
# Source du fonds : "LIST new books for SHELVES ASCI_NH Books Order_FY26.xlsx",
# feuille "LIVRES NH RECUS EN MAI 2026", colonne TIAS.
# 19 titres, 93 exemplaires.

# --- Sites du réseau -----------------------------------------------------
# Seul Tiassalé est utilisé au MVP. Les trois autres sont présents pour que
# l'ouverture aux autres antennes ne demande pas de migration plus tard.

sites = {
  "TIAS" => "American Shelf de Tiassalé",
  "ABO"  => "American Space d'Abidjan",
  "DAL"  => "American Space de Daloa",
  "SP"   => "American Space de San Pédro"
}

sites.each do |code, name|
  Site.find_or_create_by!(code: code) do |site|
    site.name   = name
    site.active = (code == "TIAS")
  end
end

tiassale = Site.find_by!(code: "TIAS")

# --- Catégories ----------------------------------------------------------
# Calées sur le fonds réel, qui est du développement professionnel.
# Les catégories de la maquette (littérature, sciences, jeunesse) ne
# correspondaient à aucun livre présent sur les étagères.

categories = {
  "communication"          => "Communication & prise de parole",
  "productivite"           => "Productivité & organisation",
  "leadership"             => "Leadership & management",
  "entrepreneuriat"        => "Entrepreneuriat & business",
  "developpement-personnel" => "Développement personnel",
  "biographies"            => "Biographies & récits"
}

categories.each do |slug, name|
  Category.find_or_create_by!(slug: slug) { |c| c.name = name }
end

cat = Category.all.index_by(&:slug)

# --- Réglages ------------------------------------------------------------
# Lus par les services métier plutôt que codés en dur, pour être modifiables
# sans redéployer l'application.

{
  "loan_days"         => "14",   # durée d'un prêt
  "max_renewals"      => "1",    # renouvellements autorisés
  "loan_quota"        => "1",    # livres simultanés par abonné
  "membership_months" => "12",   # durée de l'abonnement
  "card_prefix"       => "TSL"   # préfixe des numéros de carte : TSL-2026-0087
}.each do |key, value|
  Setting.find_or_create_by!(key: key) { |s| s.value = value }
end

# --- Le fonds ------------------------------------------------------------
#
# Le fichier source ne contenait que le titre et la quantité : ni auteur,
# ni ISBN, ni résumé.
#
# Les auteurs ci-dessous ont été identifiés à partir du titre et sont
# marqués author_confirmed: false. Le bibliothécaire doit les vérifier sur
# la couverture avant la mise en ligne du catalogue public. Les titres pour
# lesquels l'identification était incertaine ont été laissés vides plutôt
# que renseignés au jugé.

RECEPTION = Date.new(2026, 5, 1)
COLLECTION = "Nouveaux Horizons"

# rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
# Le fonds se relit comme le tableau dont il sort : une ligne par titre,
# colonnes alignées. Les espaces que réclame le style maison décaleraient
# chaque ligne et rendraient une erreur de quantité invisible.
books = [
  # titre,                                                   ex., catégorie,                auteur
  ["Parlez, l'art de parler en public",                        12, "communication",           nil],
  ["Devenez un grand orateur",                                 10, "communication",           nil],
  ["Écoutez, l'art de la communication attentive",              7, "communication",           nil],
  ["Team, s'organiser pour réussir en équipe",                  7, "productivite",            "David Allen"],
  ["S'organiser pour réussir",                                  7, "productivite",            "David Allen"],
  ["S'organiser pour réussir, la méthode GTD spéciale ados",    7, "productivite",            "David Allen"],
  ["Préparer un examen",                                        7, "productivite",            nil],
  ["L'effet cumulé, décuplez votre réussite",                   5, "productivite",            "Darren Hardy"],
  ["La Montagne, c'est toi",                                    5, "developpement-personnel", "Brianna Wiest"],
  ["Mohamed Ali, le plus Grand",                                5, "biographies",             nil],
  ["Le Grain de Café",                                          5, "developpement-personnel", "Jon Gordon"],
  ["The One Thing, passez à l'essentiel",                       2, "productivite",            "Gary Keller"],
  ["La Théorie Let Them",                                       2, "developpement-personnel", "Mel Robbins"],
  ["Le Management Multiplicateur",                              2, "leadership",              "Liz Wiseman"],
  ["Leadership, Stratégie & Tactique",                          2, "leadership",              "Jocko Willink"],
  ["Le Prix de l'Excellence",                                   2, "leadership",              "Tom Peters"],
  ["Les 7 secrets de Warren Buffet pour devenir riche",         2, "entrepreneuriat",         nil],
  ["Devenir Business Coach",                                    2, "entrepreneuriat",         nil],
  ["Devenez Riche, programme de 6 semaines",                    2, "entrepreneuriat",         "Ramit Sethi"]
]
# rubocop:enable Layout/SpaceInsideArrayLiteralBrackets

books.each do |title, copies, category_slug, author|
  book = Book.find_or_initialize_by(site: tiassale, title: title)
  book.assign_attributes(
    author:            author,
    author_confirmed:  false,
    category:          cat.fetch(category_slug),
    language:          "fr",
    collection:        COLLECTION,
    received_on:       RECEPTION,
    total_copies:      copies,
    active:            true
  )
  book.save!
end

# --- Contrôle ------------------------------------------------------------
# Le fichier source annonce 19 titres et 93 exemplaires pour Tiassalé.
# Si ces chiffres ne tombent pas juste, la saisie est fausse et il ne faut
# pas continuer.

titles  = Book.where(site: tiassale).count
copies  = Book.where(site: tiassale).sum(:total_copies)
missing = Book.where(site: tiassale, author: nil).count

raise "Fonds incorrect : #{titles} titres au lieu de 19"       unless titles == 19
raise "Fonds incorrect : #{copies} exemplaires au lieu de 93"  unless copies == 93

# --- Abonnés de référence -------------------------------------------------
#
# Six situations qui reviennent dans les maquettes Claude Design et dans les
# écrans déjà construits : à jour sans emprunt, emprunt en cours dans les
# délais, emprunt bientôt dû, emprunt en retard, adhésion bientôt expirée,
# adhésion expirée, compte suspendu. Sans ces abonnés en base, chercher
# "Diarra" ou "Kouadio" dans l'application ne renvoie rien, alors que les
# maquettes les montrent partout.
#
# Les dates sont calculées par rapport à aujourd'hui plutôt que codées en
# dur, pour que le jeu de données reste cohérent quel que soit le jour où
# les seeds sont rejoués.

MEMBRES_REFERENCE = {
  "TSL-2026-0087" => { prenom: "Aminata", nom: "Koné",      telephone: "0708451230", expire_dans: 8.months },
  "TSL-2026-0112" => { prenom: "Kouadio", nom: "N'Guessan",  telephone: "0564228904", expire_dans: 6.months },
  "TSL-2026-0034" => { prenom: "Fatou",   nom: "Diarra",     telephone: "0142776318", expire_dans: 4.months },
  "TSL-2026-0155" => { prenom: "Yao",     nom: "Kouassi",    telephone: "0791305527", expire_dans: 18.days },
  "TSL-2026-0201" => { prenom: "Adjoua",  nom: "Brou",       telephone: "0512689403", expire_dans: -12.days },
  "TSL-2026-0233" => { prenom: "Ibrahim", nom: "Traoré",     telephone: "0177054162", expire_dans: 5.months, suspendu: true }
}.freeze

MEMBRES_REFERENCE.each do |card_number, attrs|
  member = Member.find_or_initialize_by(card_number: card_number)
  member.assign_attributes(
    site:        tiassale,
    first_name:  attrs[:prenom],
    last_name:   attrs[:nom],
    phone:       attrs[:telephone],
    joined_on:   member.joined_on || Date.current - 6.months,
    expires_on:  Date.current + attrs[:expire_dans],
    suspended:   attrs[:suspendu] || false
  )
  member.save!
end

par_carte = Member.where(card_number: MEMBRES_REFERENCE.keys).index_by(&:card_number)

# Trois abonnés ont un emprunt en cours, pour illustrer les trois statuts
# affichés par badge_echeance : à temps, bientôt dû, en retard. Les trois
# autres restent volontairement sans emprunt : c'est ce qui illustre "à
# jour, libre d'emprunter", "adhésion expirée" et "suspendu".
PRETS_REFERENCE = [
  # carte,           titre de l'ouvrage,                      emprunté il y a,  échéance dans
  [ "TSL-2026-0112", "S'organiser pour réussir",                    3.days,   11.days ],
  [ "TSL-2026-0155", "The One Thing, passez à l'essentiel",        12.days,    2.days ],
  [ "TSL-2026-0034", "Devenez un grand orateur",                   20.days,   -6.days ]
].freeze

PRETS_REFERENCE.each do |card_number, titre, emprunte_il_y_a, echeance_dans|
  member = par_carte.fetch(card_number)
  book   = Book.find_by!(site: tiassale, title: titre)

  next if Loan.exists?(member: member, book: book, returned_on: nil)

  Loan.create!(
    member: member,
    book: book,
    borrowed_on: Date.current - emprunte_il_y_a,
    due_on: Date.current + echeance_dans
  )
end

puts "Sites          : #{Site.count}"
puts "Catégories     : #{Category.count}"
puts "Réglages       : #{Setting.count}"
puts "Ouvrages       : #{titles} titres, #{copies} exemplaires"
puts "Auteurs à saisir : #{missing} fiches sans auteur"
puts "Auteurs à confirmer : #{Book.where(site: tiassale, author_confirmed: false).where.not(author: nil).count} fiches"
puts "Abonnés de référence : #{Member.where(card_number: MEMBRES_REFERENCE.keys).count}"
puts "Prêts de référence   : #{Loan.where(member_id: par_carte.values.map(&:id)).open.count} en cours"
