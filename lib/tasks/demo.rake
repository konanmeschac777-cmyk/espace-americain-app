# Jeu de données de démonstration.
#
#   bin/rails demo:load     crée des abonnés et des prêts d'exemple
#   bin/rails demo:clear     supprime tout ce que demo:load a créé
#
# Ces données servent à voir les écrans dans leurs différents états sans
# attendre d'avoir de vrais abonnés. Elles ne doivent jamais atteindre la
# production : la tâche refuse de s'exécuter dans cet environnement.
#
# Les ouvrages, eux, ne sont PAS touchés : ils viennent de db/seeds.rb et
# correspondent au fonds réel.

namespace :demo do
  desc "Crée des abonnés et des prêts de démonstration"
  task load: :environment do
    abort "Refusé : demo:load ne s'exécute pas en production." if Rails.env.production?

    site = Site.find_by(code: "TIAS")
    abort "Lance d'abord bin/rails db:seed, le site TIAS est introuvable." if site.nil?

    today = Date.current

    # Chaque abonné couvre un état que les écrans doivent savoir afficher.
    people = [
      # carte,           prénom,    nom,          téléphone,           expire le,        suspendu, cas couvert
      [ "TSL-2026-0087", "Aminata", "Koné",       "07 08 45 12 30", today >> 7,      false ], # à jour, libre d'emprunter
      [ "TSL-2026-0112", "Kouadio", "N'Guessan",  "05 64 22 89 04", today >> 5,      false ], # a déjà un livre
      [ "TSL-2026-0034", "Fatou",   "Diarra",     "01 42 77 63 18", today >> 9,      false ], # a un livre en retard
      [ "TSL-2026-0155", "Yao",     "Kouassi",    "07 91 30 55 27", today + 18,      false ], # abonnement expire bientôt
      [ "TSL-2026-0201", "Adjoua",  "Brou",       "05 12 68 94 03", today - 12,      false ], # abonnement expiré
      [ "TSL-2026-0233", "Ibrahim", "Traoré",     "01 77 05 41 62", today >> 4,      true  ]  # suspendu
    ]

    members = people.map do |card, first, last, phone, expires, suspended|
      member = Member.find_or_initialize_by(card_number: card)
      member.assign_attributes(
        site: site,
        first_name: first,
        last_name: last,
        phone: phone,
        joined_on: expires >> -Setting.membership_months,
        expires_on: expires,
        suspended: suspended
      )
      member.save!
      member
    end.index_by(&:card_number)

    # Prêts en cours. On repart de zéro pour que relancer la tâche ne
    # produise pas plusieurs prêts ouverts pour la même personne.
    Loan.where(member: members.values).destroy_all

    loans = [
      # abonné,          titre,                                       emprunté il y a, cas couvert
      [ "TSL-2026-0112", "S'organiser pour réussir",                    3 ],  # dans les délais
      [ "TSL-2026-0034", "Devenez un grand orateur",                   20 ],  # en retard de 6 jours
      [ "TSL-2026-0155", "The One Thing, passez à l'essentiel",        12 ]   # dû dans 2 jours
    ]

    loans.each do |card, title, days_ago|
      book = Book.find_by!(title: title)
      borrowed = today - days_ago

      Loan.create!(
        book: book,
        member: members.fetch(card),
        borrowed_on: borrowed,
        due_on: borrowed + Setting.loan_days,
        renewals_count: 0
      )
    end

    # Un prêt déjà rendu, pour que l'historique d'une fiche abonné ne soit
    # pas vide au premier coup d'œil.
    Loan.create!(
      book: Book.find_by!(title: "Le Grain de Café"),
      member: members.fetch("TSL-2026-0087"),
      borrowed_on: today - 40,
      due_on: today - 26,
      returned_on: today - 28,
      renewals_count: 0
    )

    puts "Abonnés         : #{Member.count}"
    puts "  dont suspendu : #{Member.suspended.count}"
    puts "  expirés       : #{Member.expired.count}"
    puts "  expire bientôt: #{Member.expiring_soon.count}"
    puts "Prêts en cours  : #{Loan.open.count}"
    puts "  dont en retard: #{Loan.overdue.count}"
    puts "Prêts terminés  : #{Loan.returned.count}"
  end

  desc "Supprime les abonnés et prêts de démonstration"
  task clear: :environment do
    abort "Refusé : demo:clear ne s'exécute pas en production." if Rails.env.production?

    Loan.destroy_all
    Member.destroy_all

    puts "Supprimé. Abonnés : #{Member.count}, prêts : #{Loan.count}."
    puts "Les #{Book.count} ouvrages du fonds sont intacts."
  end
end
