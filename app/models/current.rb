class Current < ActiveSupport::CurrentAttributes
  attribute :session

  # Les réglages lus pendant la requête en cours. Setting.loan_days est
  # appelé plusieurs fois par écran — une fois par ligne dans une liste de
  # prêts — et chaque appel touchait la base.
  #
  # La portée est la requête, et pas plus : un réglage modifié vaut dès
  # l'écran suivant, sans cache à vider ni redémarrage. C'est aussi ce qui
  # rend la chose sûre quand plusieurs processus servent l'application.
  attribute :reglages

  delegate :user, to: :session, allow_nil: true
end
