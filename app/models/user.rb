# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :registerable
  devise :database_authenticatable, :recoverable,
         :rememberable, :validatable
end
