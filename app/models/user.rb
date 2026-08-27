class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Utilisées par l'avatar du tableau de bord, du tiroir de navigation et
  # de la page compte : jamais une valeur en dur, toujours dérivées de
  # l'adresse email réelle du compte.
  def initials = email_address.split("@").first.first(3).upcase
end
