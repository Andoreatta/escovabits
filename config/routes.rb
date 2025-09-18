Rails.application.routes.draw do
  root "compiler#index"
  post "compile", to: "compiler#compile"
end
