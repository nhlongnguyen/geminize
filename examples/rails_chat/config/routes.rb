# frozen_string_literal: true

Rails.application.routes.draw do
  # Chat routes
  get "chat", to: "chat#index"
  post "chat", to: "chat#create"
  post "chat/reset", to: "chat#reset", as: :reset_chat
end
