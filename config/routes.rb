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
  resources :loans, path: "prets", path_names: { new: "nouveau" }, only: [ :new, :create ]

  # Le retour est une ressource à part entière et non une mise à jour du
  # prêt : c'est un geste du comptoir, avec son écran et son succès.
  resources :returns, path: "retours", path_names: { new: "nouveau" }, only: [ :new, :create ]

  resources :members, path: "abonnes", path_names: { new: "nouveau" }, only: [ :new, :create ] do
    # Réinscription annuelle. L'adhésion est gratuite, c'est une simple
    # autorisation à enregistrer.
    post :renew, on: :member, path: "prolonger"
  end

  # Provisoire : le prêt est le geste le plus fréquent, il tient lieu
  # d'accueil en attendant le tableau de bord.
  root "loans#new"
end
