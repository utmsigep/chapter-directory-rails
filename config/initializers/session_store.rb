# frozen_string_literal: true

Rails.application.config.session_store :cookie_store, key: "_my_name_#{Rails.env}", expire_after: 1.year, domain: :all
