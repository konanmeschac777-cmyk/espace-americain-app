# Un abonné. L'adhésion est gratuite et vaut un an.
#
# L'expiration ne sert donc pas à faire payer, mais à savoir qui fréquente
# encore l'Espace : une carte d'un an oblige à repasser au comptoir, ce qui
# tient la liste à jour. La réinscription est un simple geste d'autorisation.
class Member < ApplicationRecord
  belongs_to :site
  has_many :loans, dependent: :restrict_with_error

  EXPIRING_SOON_DAYS = 30

  # Indicatifs téléphoniques par pays, pour le champ téléphone : indicatif,
  # nom en français, code ISO du pays (sert à générer le drapeau). La Côte
  # d'Ivoire est en tête : c'est le cas de presque tous les abonnés, elle
  # doit rester le premier choix plutôt que d'être noyée dans l'ordre
  # alphabétique. Le reste suit l'ordre alphabétique du nom en français.
  INDICATIFS_TELEPHONIQUES = [
    [ "+225", "Côte d'Ivoire", "CI" ],
    [ "+93", "Afghanistan", "AF" ], [ "+27", "Afrique du Sud", "ZA" ], [ "+355", "Albanie", "AL" ],
    [ "+213", "Algérie", "DZ" ], [ "+49", "Allemagne", "DE" ], [ "+376", "Andorre", "AD" ],
    [ "+244", "Angola", "AO" ], [ "+1", "Antigua-et-Barbuda", "AG" ], [ "+54", "Argentine", "AR" ],
    [ "+374", "Arménie", "AM" ], [ "+61", "Australie", "AU" ], [ "+43", "Autriche", "AT" ],
    [ "+994", "Azerbaïdjan", "AZ" ], [ "+1", "Bahamas", "BS" ], [ "+973", "Bahreïn", "BH" ],
    [ "+880", "Bangladesh", "BD" ], [ "+1", "Barbade", "BB" ], [ "+375", "Biélorussie", "BY" ],
    [ "+32", "Belgique", "BE" ], [ "+501", "Belize", "BZ" ], [ "+229", "Bénin", "BJ" ],
    [ "+975", "Bhoutan", "BT" ], [ "+591", "Bolivie", "BO" ], [ "+387", "Bosnie-Herzégovine", "BA" ],
    [ "+267", "Botswana", "BW" ], [ "+55", "Brésil", "BR" ], [ "+673", "Brunei", "BN" ],
    [ "+359", "Bulgarie", "BG" ], [ "+226", "Burkina Faso", "BF" ], [ "+257", "Burundi", "BI" ],
    [ "+855", "Cambodge", "KH" ], [ "+237", "Cameroun", "CM" ], [ "+1", "Canada", "CA" ],
    [ "+238", "Cap-Vert", "CV" ], [ "+56", "Chili", "CL" ], [ "+86", "Chine", "CN" ],
    [ "+357", "Chypre", "CY" ], [ "+57", "Colombie", "CO" ], [ "+269", "Comores", "KM" ],
    [ "+242", "Congo-Brazzaville", "CG" ], [ "+243", "Congo (RDC)", "CD" ], [ "+82", "Corée du Sud", "KR" ],
    [ "+850", "Corée du Nord", "KP" ], [ "+506", "Costa Rica", "CR" ], [ "+385", "Croatie", "HR" ],
    [ "+53", "Cuba", "CU" ], [ "+45", "Danemark", "DK" ], [ "+253", "Djibouti", "DJ" ],
    [ "+1", "Dominique", "DM" ], [ "+20", "Égypte", "EG" ], [ "+971", "Émirats arabes unis", "AE" ],
    [ "+593", "Équateur", "EC" ], [ "+291", "Érythrée", "ER" ], [ "+34", "Espagne", "ES" ],
    [ "+372", "Estonie", "EE" ], [ "+268", "Eswatini", "SZ" ], [ "+1", "États-Unis", "US" ],
    [ "+251", "Éthiopie", "ET" ], [ "+679", "Fidji", "FJ" ], [ "+358", "Finlande", "FI" ],
    [ "+33", "France", "FR" ], [ "+241", "Gabon", "GA" ], [ "+220", "Gambie", "GM" ],
    [ "+995", "Géorgie", "GE" ], [ "+233", "Ghana", "GH" ], [ "+30", "Grèce", "GR" ],
    [ "+1", "Grenade", "GD" ], [ "+502", "Guatemala", "GT" ], [ "+224", "Guinée", "GN" ],
    [ "+245", "Guinée-Bissau", "GW" ], [ "+240", "Guinée équatoriale", "GQ" ], [ "+592", "Guyana", "GY" ],
    [ "+509", "Haïti", "HT" ], [ "+504", "Honduras", "HN" ], [ "+36", "Hongrie", "HU" ],
    [ "+91", "Inde", "IN" ], [ "+62", "Indonésie", "ID" ], [ "+964", "Irak", "IQ" ],
    [ "+98", "Iran", "IR" ], [ "+353", "Irlande", "IE" ], [ "+354", "Islande", "IS" ],
    [ "+972", "Israël", "IL" ], [ "+39", "Italie", "IT" ], [ "+1", "Jamaïque", "JM" ],
    [ "+81", "Japon", "JP" ], [ "+962", "Jordanie", "JO" ], [ "+7", "Kazakhstan", "KZ" ],
    [ "+254", "Kenya", "KE" ], [ "+996", "Kirghizistan", "KG" ], [ "+686", "Kiribati", "KI" ],
    [ "+383", "Kosovo", "XK" ], [ "+965", "Koweït", "KW" ], [ "+856", "Laos", "LA" ],
    [ "+371", "Lettonie", "LV" ], [ "+961", "Liban", "LB" ], [ "+231", "Liberia", "LR" ],
    [ "+218", "Libye", "LY" ], [ "+423", "Liechtenstein", "LI" ], [ "+370", "Lituanie", "LT" ],
    [ "+352", "Luxembourg", "LU" ], [ "+389", "Macédoine du Nord", "MK" ], [ "+261", "Madagascar", "MG" ],
    [ "+60", "Malaisie", "MY" ], [ "+265", "Malawi", "MW" ], [ "+960", "Maldives", "MV" ],
    [ "+223", "Mali", "ML" ], [ "+356", "Malte", "MT" ], [ "+212", "Maroc", "MA" ],
    [ "+692", "Îles Marshall", "MH" ], [ "+230", "Maurice", "MU" ], [ "+222", "Mauritanie", "MR" ],
    [ "+52", "Mexique", "MX" ], [ "+691", "Micronésie", "FM" ], [ "+373", "Moldavie", "MD" ],
    [ "+377", "Monaco", "MC" ], [ "+976", "Mongolie", "MN" ], [ "+382", "Monténégro", "ME" ],
    [ "+258", "Mozambique", "MZ" ], [ "+95", "Birmanie (Myanmar)", "MM" ], [ "+264", "Namibie", "NA" ],
    [ "+674", "Nauru", "NR" ], [ "+977", "Népal", "NP" ], [ "+505", "Nicaragua", "NI" ],
    [ "+227", "Niger", "NE" ], [ "+234", "Nigeria", "NG" ], [ "+47", "Norvège", "NO" ],
    [ "+64", "Nouvelle-Zélande", "NZ" ], [ "+968", "Oman", "OM" ], [ "+256", "Ouganda", "UG" ],
    [ "+998", "Ouzbékistan", "UZ" ], [ "+92", "Pakistan", "PK" ], [ "+680", "Palaos", "PW" ],
    [ "+970", "Palestine", "PS" ], [ "+507", "Panama", "PA" ], [ "+675", "Papouasie-Nouvelle-Guinée", "PG" ],
    [ "+595", "Paraguay", "PY" ], [ "+31", "Pays-Bas", "NL" ], [ "+51", "Pérou", "PE" ],
    [ "+63", "Philippines", "PH" ], [ "+48", "Pologne", "PL" ], [ "+351", "Portugal", "PT" ],
    [ "+974", "Qatar", "QA" ], [ "+420", "République tchèque", "CZ" ], [ "+236", "République centrafricaine", "CF" ],
    [ "+1", "République dominicaine", "DO" ], [ "+40", "Roumanie", "RO" ], [ "+44", "Royaume-Uni", "GB" ],
    [ "+7", "Russie", "RU" ], [ "+250", "Rwanda", "RW" ], [ "+1", "Saint-Kitts-et-Nevis", "KN" ],
    [ "+378", "Saint-Marin", "SM" ], [ "+1", "Saint-Vincent-et-les-Grenadines", "VC" ], [ "+1", "Sainte-Lucie", "LC" ],
    [ "+677", "Salomon", "SB" ], [ "+685", "Samoa", "WS" ], [ "+239", "Sao Tomé-et-Principe", "ST" ],
    [ "+221", "Sénégal", "SN" ], [ "+381", "Serbie", "RS" ], [ "+248", "Seychelles", "SC" ],
    [ "+232", "Sierra Leone", "SL" ], [ "+65", "Singapour", "SG" ], [ "+421", "Slovaquie", "SK" ],
    [ "+386", "Slovénie", "SI" ], [ "+252", "Somalie", "SO" ], [ "+249", "Soudan", "SD" ],
    [ "+211", "Soudan du Sud", "SS" ], [ "+94", "Sri Lanka", "LK" ], [ "+46", "Suède", "SE" ],
    [ "+41", "Suisse", "CH" ], [ "+597", "Suriname", "SR" ], [ "+963", "Syrie", "SY" ],
    [ "+992", "Tadjikistan", "TJ" ], [ "+255", "Tanzanie", "TZ" ], [ "+886", "Taïwan", "TW" ],
    [ "+235", "Tchad", "TD" ], [ "+66", "Thaïlande", "TH" ], [ "+670", "Timor oriental", "TL" ],
    [ "+228", "Togo", "TG" ], [ "+676", "Tonga", "TO" ], [ "+1", "Trinité-et-Tobago", "TT" ],
    [ "+216", "Tunisie", "TN" ], [ "+993", "Turkménistan", "TM" ], [ "+90", "Turquie", "TR" ],
    [ "+688", "Tuvalu", "TV" ], [ "+380", "Ukraine", "UA" ], [ "+598", "Uruguay", "UY" ],
    [ "+678", "Vanuatu", "VU" ], [ "+379", "Vatican", "VA" ], [ "+58", "Venezuela", "VE" ],
    [ "+84", "Viêt Nam", "VN" ], [ "+967", "Yémen", "YE" ], [ "+260", "Zambie", "ZM" ],
    [ "+263", "Zimbabwe", "ZW" ]
  ].freeze

  # Émoji drapeau à partir d'un code pays ISO (deux lettres) : chaque
  # lettre devient un "regional indicator symbol" Unicode, la paire
  # s'affiche comme un drapeau sur la quasi-totalité des systèmes.
  def self.drapeau(code_iso)
    code_iso.upcase.each_char.map { |lettre| (127397 + lettre.ord).chr(Encoding::UTF_8) }.join
  end

  validates :card_number, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :joined_on, :expires_on, presence: true
  validates :age, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

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

  # Une suspension est soit manuelle et indéfinie (`suspended`), soit
  # automatique et temporaire, posée par un retour en retard
  # (`suspended_until`). Les deux se lisent comme un seul état pour
  # l'emprunt : suspendu, ou pas.
  def currently_suspended?
    suspended? || (suspended_until.present? && suspended_until >= Date.current)
  end

  # Renvoie le motif qui interdit l'emprunt, ou nil si la voie est libre.
  # L'écran de prêt affiche un bandeau différent pour chaque motif, c'est
  # pourquoi on retourne la raison et pas un simple faux.
  def borrow_block_reason
    return :suspended         if currently_suspended?
    return :membership_expired if membership_expired?
    return :already_borrowing  if loans.open.count >= Setting.loan_quota

    nil
  end

  # Lève une suspension automatique posée par un retard. N'a aucun effet
  # sur une suspension manuelle : celle-là se lève au dossier de l'abonné,
  # pas depuis l'écran de retour.
  def lift_suspension!
    update!(suspended_until: nil)
  end

  # Suspension manuelle, décidée par le responsable (vol, dégradation,
  # comportement...). Indépendante de la suspension automatique posée par
  # un retard : suspendre ici n'efface pas un `suspended_until` en cours,
  # et le lever ici ne touche pas non plus à ce dernier.
  def suspend!
    update!(suspended: true)
  end

  def unsuspend!
    update!(suspended: false)
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
