# Gestion des comptes bibliothécaires.
#
#   bin/rails "bibliothecaire:creer[email@exemple.ci,motdepasse]"
#   bin/rails bibliothecaire:lister
#
# Il n'y a pas d'écran d'inscription dans l'application, et c'est voulu :
# un espace bibliothécaire ne doit pas permettre à un inconnu de se créer
# un compte. Les comptes se créent ici, en ligne de commande.

namespace :bibliothecaire do
  desc "Crée un compte bibliothécaire : bibliothecaire:creer[email,motdepasse]"
  task :creer, [ :email, :password ] => :environment do |_task, args|
    email    = args[:email].to_s.strip
    password = args[:password].to_s

    abort "Usage : bin/rails \"bibliothecaire:creer[email@exemple.ci,motdepasse]\"" if email.empty? || password.empty?
    abort "Mot de passe trop court : 8 caractères minimum." if password.length < 8

    user = User.find_or_initialize_by(email_address: email)
    nouveau = user.new_record?
    user.password = password
    user.save!

    puts nouveau ? "Compte créé : #{user.email_address}" : "Mot de passe mis à jour : #{user.email_address}"
    puts "Comptes existants : #{User.count}"
  end

  desc "Liste les comptes bibliothécaires"
  task lister: :environment do
    if User.none?
      puts "Aucun compte. Crée-en un avec bibliothecaire:creer."
    else
      User.order(:email_address).each do |u|
        sessions = u.sessions.count
        puts "#{u.email_address}  (#{sessions} session#{'s' if sessions > 1} active#{'s' if sessions > 1})"
      end
    end
  end
end
