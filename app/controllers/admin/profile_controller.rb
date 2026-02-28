# frozen_string_literal: true

module Admin
  class ProfileController < ApplicationController
    before_action :set_user

    def edit; end

    def update
      user_attributes = profile_params

      if user_attributes[:password].blank?
        user_attributes = user_attributes.except(:password, :password_confirmation)
        return redirect_to(admin_profile_path, notice: 'Profile was successfully updated.') if @user.update_without_password(user_attributes)
      elsif @user.update(user_attributes)
        return redirect_to(admin_profile_path, notice: 'Profile was successfully updated.')
      end

      render :edit, status: :unprocessable_entity
    end

    private

    def set_user
      @user = current_user
    end

    def profile_params
      params.fetch(:user, {}).permit(:email, :password, :password_confirmation)
    end
  end
end
