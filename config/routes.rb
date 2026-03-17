Rails.application.routes.draw do
  get "/:slug", to: "public_clients#show", as: :public_client

  # ouverture du formulaire + création du pending
  get "/:slug/services/:service_id/bookings/new", to: "bookings#new", as: :new_service_booking

  # confirmation du booking
  post "/:slug/bookings/:id/confirm", to: "bookings#create", as: :confirm_booking

  # page succès
  get "/:slug/bookings/:id/success", to: "bookings#success", as: :booking_success
end
