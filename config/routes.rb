Rails.application.routes.draw do
  root "home#index"

  namespace :internal, defaults: { format: :json } do
    resources :platforms, only: [:show]
    resource  :refresh_statuses,     only: [:create], path: "refresh-statuses"
    resource  :send_unread_messages, only: [:create], path: "send-unread-messages"
    resource  :message_deletions,    only: [:create], path: "message-deletions"
  end

  namespace :user, defaults: { format: :json } do
    resource :user,               only: [:show],   controller: "user", path: "/"
    resource :alive,              only: [:update], controller: "alive"
    resources :rooms,             only: [:index, :show, :create, :update, :destroy] do
      resources :messages,        only: [:index, :create, :destroy]
      resources :memberships,     only: [:create]
      resource  :membership,      only: [:update], controller: "membership" do
        resource :unread_messages, only: [:update], path: "unread-messages", controller: "unread_messages"
      end
    end
  end

  namespace :platform, defaults: { format: :json } do
    resources :users,            only: [:index, :create, :update, :destroy] do
      resources :tokens,         only: [:create]
    end
    resources :rooms,            only: [:index, :show, :create, :update, :destroy] do
      resources :messages,       only: [:index, :create, :destroy]
      resources :users,          only: [:index], controller: "rooms/users" do
        resource :membership,    only: [:create, :destroy]
      end
    end
  end
end
