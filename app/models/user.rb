# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :registerable
  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable

  # Define roles as constants
  ROLES = %w[admin editor user].freeze

  # Method to check if the user has a certain role
  def has_role?(role_name)
    role == role_name.to_s
  end

  # Helper methods to check for specific roles
  def admin?
    has_role?('admin')
  end

  def editor?
    has_role?('editor') || has_role?('admin')
  end

  def user?
    has_role?('user') || has_role?('editor') || has_role?('admin')
  end
end
