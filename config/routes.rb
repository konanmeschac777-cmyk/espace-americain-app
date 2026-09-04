Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Back-office. Les chemins sont en français, le code reste en anglais.
  # path_names est nécessaire en plus de path : sans lui, Rails garderait
  # /prets/new au lieu de /prets/nouveau.
  resources :loans, path: "prets", path_names: { new: "nouveau" }, only: [ :index, :new, :create ] do
    # Prolonge un prêt de 14 jours, une seule fois.
    post :renew, on: :member, path: "renouveler"
  end

  # Le retour est une ressource à part entière et non une mise à jour du
  # prêt : c'est un geste du comptoir, avec son écran et son succès.
  resources :returns, path: "retours", path_names: { new: "nouveau" }, only: [ :new, :create ]

  resources :members, path: "abonnes", path_names: { new: "nouveau", edit: "modifier" },
                       only: [ :index, :show, :new, :create, :edit, :update ] do
    # Réinscription annuelle. L'adhésion est gratuite, c'est une simple
    # autorisation à enregistrer.
    post :renew, on: :member, path: "prolonger"

    # Suspension manuelle, décidée par le responsable (à distinguer de la
    # suspension automatique posée par un retour en retard).
    post :suspend, on: :member, path: "suspendre"
    post :lift_suspend, on: :member, path: "lever-suspension"
  end

  resources :books, path: "ouvrages", path_names: { new: "nouveau", edit: "modifier" },
                     only: [ :index, :show, :new, :create, :edit, :update ] do
    # Retire un ouvrage du catalogue sans le supprimer : son historique de
    # prêts reste consultable.
    post :archive, on: :member, path: "archiver"
  end

  # Écran 00 de la maquette : couverture avant connexion. Redirige vers le
  # tableau de bord si le bibliothécaire est déjà connecté.
  root "pages#accueil"

  # Écran 10 : ce que le bibliothécaire voit une fois connecté.
  get "tableau-de-bord", to: "pages#tableau_de_bord", as: :tableau_de_bord

  # Écran 11 : les chiffres du mois.
  get "rapport-du-mois", to: "pages#rapport_du_mois", as: :rapport_du_mois

  # Écran 20 : informatif pour l'instant, seul le français existe vraiment.
  get "langue", to: "pages#langue", as: :langue

  # Les règles du comptoir : durée d'un prêt, quota, durée d'adhésion.
  # Une ressource au singulier : il n'y a qu'un jeu de réglages, pas de
  # liste à parcourir ni d'identifiant à passer dans l'adresse.
  resource :reglages, only: [ :show, :update ], controller: "settings"

  # Informations du compte connecté (atteint depuis l'avatar du tableau de
  # bord). C'est ici que se trouve la déconnexion.
  get "compte", to: "pages#compte", as: :compte
end
