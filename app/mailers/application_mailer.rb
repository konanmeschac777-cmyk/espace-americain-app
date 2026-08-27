class ApplicationMailer < ActionMailer::Base
  # Relais temporaire : konanmeschac777@gmail.com, en attendant l'accès au
  # compte réel du responsable (astiassale@gmail.com, voir mémoire du
  # projet). Gmail exige que le "from" corresponde au compte qui envoie
  # réellement, sinon le message est rejeté ou réécrit silencieusement.
  default from: "American Shelf de Tiassalé <konanmeschac777@gmail.com>"
  layout "mailer"
end
