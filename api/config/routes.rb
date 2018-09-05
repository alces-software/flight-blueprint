Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Ensure there is a simple route for uptime-robot to request.
  get '/status' => (lambda do |req|
    [200, {}, ["OK"]]
  end)
end
