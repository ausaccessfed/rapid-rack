Rails.application.routes.draw do
  mount RapidRack::Engine => '/auth'
end
