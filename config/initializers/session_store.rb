# Be sure to restart your server when you modify this file.

CnpeNew::Application.config.session_store :cookie_store, key: '_cnpe_new_session'
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
