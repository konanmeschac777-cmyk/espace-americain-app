require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # L'application tourne sur le serveur local de l'Espace : les téléphones du
  # comptoir l'atteignent en http:// sur le réseau de la bibliothèque, où il
  # n'y a ni certificat ni proxy devant. Forcer le HTTPS renverrait chaque
  # requête vers une adresse https:// qui n'existe pas — le serveur
  # démarrerait normalement mais aucun écran ne s'afficherait, sans le
  # moindre message pour expliquer pourquoi.
  #
  # RAILS_FORCE_SSL=true pour la future instance en ligne du portail public,
  # qui sera, elle, derrière un vrai certificat.
  ssl_required = ENV["RAILS_FORCE_SSL"] == "true"

  config.assume_ssl = ssl_required
  config.force_ssl  = ssl_required

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Le serveur local de l'Espace tourne sans internet : aucun e-mail ne peut
  # partir. L'écran "mot de passe oublié" le dit d'emblée et renvoie vers la
  # tâche bibliothecaire:creer (lib/tasks/librarian.rake), qui redonne un mot
  # de passe depuis le poste, plutôt que de faire remplir un formulaire dont
  # rien ne sortira.
  config.x.offline_server = ENV["OFFLINE_SERVER"] == "true"

  # Adresse écrite dans les liens des e-mails. Sur le serveur local, c'est
  # celle du poste sur le réseau de l'Espace (APP_HOST=192.168.1.50), sinon
  # le lien de réinitialisation renverrait vers une machine inexistante.
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost"),
    protocol: ssl_required ? "https" : "http"
  }

  # Gmail (astiassale@gmail.com) sert de serveur d'envoi : c'est ce compte
  # qui délivre le lien de "mot de passe oublié". Sur le serveur local sans
  # internet, cet envoi échoue forcément : PasswordsController rattrape
  # l'erreur et affiche la marche à suivre au comptoir. C'est pour ça que
  # raise_delivery_errors reste à true — une panne d'envoi silencieuse
  # laisserait le bibliothécaire attendre un e-mail qui n'arrivera jamais.
  #
  # Le mot de passe utilisé
  # ici doit être un mot de passe d'application Google (pas le mot de passe
  # du compte), généré depuis myaccount.google.com/apppasswords une fois la
  # validation en deux étapes activée sur ce compte.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: Rails.application.credentials.dig(:smtp, :user_name),
    password: Rails.application.credentials.dig(:smtp, :password),
    address: "smtp.gmail.com",
    port: 587,
    domain: "gmail.com",
    authentication: :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.raise_delivery_errors = true

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Volontairement laissé vide. En production, Rails n'applique aucun filtre
  # de Host tant que cette liste est vide, ce qui est exactement ce qu'il
  # faut ici : le serveur ne répond que sur le réseau de l'Espace, et son
  # adresse change au gré du routeur. Y inscrire une adresse en dur ferait
  # tomber tout le comptoir le jour où la box redistribue les IP.
  #
  # À renseigner en revanche sur l'instance en ligne du portail public, qui
  # sera exposée à internet :
  # config.hosts = [ "shelf-tiassale.ci", /.*\.shelf-tiassale\.ci/ ]
end
