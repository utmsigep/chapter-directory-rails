# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def require_role(role)
    return if current_user&.send("#{role}?")

    flash[:alert] = 'You do not have permission to access this page.'
    redirect_to(root_path)
  end
end
