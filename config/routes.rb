Rails.application.routes.draw do
  root "compiler#index"
  post "compile", to: "compiler#compile"
  get "hello_world", to: "compiler#hello_world"
end
