Rails.application.routes.draw do
  match '/404', :to => 'errors#not_found', :via => :all
  match '/500', :to => 'errors#internal_server_error', :via => :all
  root 'static_pages#home'
  # get '/about' => 'static_pages#about'

  get '/logo', to: 'static_pages#logo'

  # get '/elements' => 'static_pages#elements'

  get '/shopping_lists' => 'shopping_lists#index'
  get '/shopping_lists/new' => 'shopping_lists#new'
  get '/shopping_lists/current' => 'shopping_lists#show_ingredients_current', as: :current_shopping_list_ingredients
  get '/shopping_lists/current/shop' => 'shopping_lists#shop'
  get '/shopping_lists/archive_current' => 'shopping_lists#archive_shopping_list'
  post '/shopping_lists' => 'shopping_lists#create'
  post '/shopping_lists/autosave' => 'shopping_lists#autosave'
  post '/shopping_lists/autosave_checked_items' => 'shopping_lists#autosave_checked_items'
  post '/shopping_lists/reminder_email' => 'shopping_lists#send_shopping_list_reminder', as: :shopping_list_delay__with_notification
  post '/shopping_lists/no_reminder_email' => 'shopping_lists#delay_shopping_list_process', as: :shopping_list_delay
  post '/shopping_lists/shopping_list_to_cupboard' => 'shopping_lists#shopping_list_to_cupboard'
  get '/shopping_lists/:id' => 'shopping_lists#show_ingredients', as: :shopping_list_ingredients
  get '/shopping_lists/:id/edit' => 'shopping_lists#edit', as: :edit_shopping_list
  patch '/shopping_lists/:id' => 'shopping_lists#update'
  delete '/shopping_lists/:id/delete' => 'shopping_lists#delete', as: :delete_shopping_list


  get 'password_resets/new'
  get 'password_resets/edit'

  get 'sessions/new'

  get '/recipes/new' => 'recipes#new'
  get '/recipes/favourites' => 'recipes#favourites', as: :favourite_recipes
  get '/recipes/yours' => 'recipes#yours', as: :your_recipes
  post '/recipes/update_matches' => 'recipes#update_recipe_matches'
  get '/recipes/:id/add_to_shopping_list' => 'recipes#add_to_shopping_list'
  get '/recipes/:id/favourite' => 'recipes#favourite'
  get '/recipes/:id/publish_update' => 'recipes#publish_update', as: :publish_update_recipe
  get '/recipes/:id/delete' => 'recipes#delete', as: :recipe_delete
  post '/recipes' => 'recipes#create'

  get '/portions/new' => 'portions#new'
  get '/portions/:id' => 'portions#show', as: :portion
  post '/portions' => 'portions#create'

  get '/stocks' => 'stocks#index'
  get '/stocks/new' => 'stocks#new_no_id', as: :stocks_new_no_id
  get '/stocks/new/:cupboard_id' => 'stocks#new', as: :stocks_new
  get '/stocks/picks' => 'stocks#picks'
  get '/stocks/:id' => 'stocks#show', as: :stock
  get '/stocks/:id/edit' => 'stocks#edit', as: :edit_stock
  get '/stocks/delete/:id' => 'stocks#delete_stock', as: :delete_stock
  patch '/stocks/:id' => 'stocks#update'
  post '/stocks' => 'stocks#create'
  post '/stocks/add_portion' => 'stocks#add_shopping_list_portion'
  post '/stocks/add_shopping_list' => 'stocks#add_shopping_list'
  post '/stocks/new/:cupboard_id' => 'stocks#create'
  post '/stocks/delete/:id' => 'stocks#delete_stock', as: :delete_stock_post

  get '/cupboards' => 'cupboards#index'
  get '/cupboards/new' => 'cupboards#new'
  # get '/cupboards/edit_all' => 'cupboards#edit_all', as: :edit_all_cupboard
  get '/cupboards/share/:id' => 'cupboards#share', as: :cupboard_share
  get '/cupboards/accept_cupboard_invite' => 'cupboards#accept_cupboard_invite'
  get '/cupboards/:id' => 'cupboards#index'
  post '/cupboards/accept_cupboard_invite' => 'cupboards#accept_cupboard_invite', as: :accept_cupboard_invite
  # get '/cupboards/sharing_request' => 'cupboards#sharing_request', as: :cupboard_sharing_request
  get '/cupboards/:id/edit' => 'cupboards#edit', as: :edit_cupboard
  patch '/cupboards/:id/edit' => 'cupboards#update'
  post '/cupboards' => 'cupboards#create'
  post '/cupboards/autosave' => 'cupboards#autosave'
  post '/cupboards/autosave_sorting' => 'cupboards#autosave_sorting'
  post '/cupboards/share/:id' => 'cupboards#share_request'
  post '/cupboards/delete_quick_add_stock' => 'cupboards#delete_quick_add_stock'
  post '/cupboards/delete_cupboard_stock' => 'cupboards#delete_cupboard_stock'
  post '/cupboards/delete_cupboard_user' => 'cupboards#delete_cupboard_user'

  get '/ingredients' => 'ingredients#index'
  get '/ingredients/new' => 'ingredients#new'
  get '/ingredients/:id' => 'ingredients#show', as: :ingredient
  get '/ingredients/:id/edit' => 'ingredients#edit', as: :edit_ingredient
  patch '/ingredients/:id' => 'ingredients#update'
  post '/ingredients' => 'ingredients#create'

  get  '/signup',  to: 'users#new', as: :users_new
  post '/signup',  to: 'users#create'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  delete '/demo_logout',   to: 'sessions#demo_logout'

  get '/quick_add_stock/new', to: 'user_fav_stocks#new'
  get '/quick_add_stock/:id/edit', to: 'user_fav_stocks#edit', as: :quick_add_stock_edit

  get '/profile', to: 'users#show', as: :user_profile
  get '/profile/edit', to: 'users#edit', as: :user_profile_edit
  post '/users/notifications', to: 'users#notifications'
  get '/google_login', to: redirect('/auth/google_oauth2')
  get '/auth/google_oauth2/callback', to: 'users#google_auth'

  post '/feedback/submit' => 'feedback#submit'

  get '/planner', to: 'planner#index', as: :planner
  get '/planner/shopping_list', to: 'planner#get_shopping_list_content'
  post '/planner/recipe_add', to: 'planner#recipe_add_to_planner'
  post '/planner/recipe_update', to: 'planner#recipe_update_in_planner'
  post '/planner/recipe_delete', to: 'planner#delete_recipe_from_planner'

  resources :users
  resources :user_fav_stocks
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :recipes do
    put :favourite, on: :member
    put :add_to_shopping_list, on: :member
  end
end
