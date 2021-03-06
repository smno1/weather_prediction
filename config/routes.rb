Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
    get '/weather/locations', to: 'data#locations'
    get '/weather/data/:location_id/:date', to: 'data#location_weather', constraints: {location_id: /[a-zA-Z_]+/, date: /(\d{2}-){2}\d{4}/}
    get '/weather/data/:post_code/:date', to: 'data#postcode_weather', constraints: {post_code: /3\d{3}/, date: /(\d{2}-){2}\d{4}/}
    get '/weather/prediction/:post_code/:period', to: 'prediction#postcode_weather', constraints: {post_code: /3\d{3}/, period: /10|30|60|120|180/}
    get '/weather/prediction/:lat/:long/:period', to: 'prediction#coordinate_weather', constraints: {lat:/-\d{2,3}\.?\d*/,long:/\d{2,3}\.?\d*/, period: /10|30|60|120|180/}
 
 
  # You can have the root of your site routed with "root"
   root 'data#locations'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end