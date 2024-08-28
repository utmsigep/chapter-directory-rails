module Admin
  class UsersController < ApplicationController
    before_action :set_user, only: %i[show edit update destroy]
    before_action -> { require_role(:admin) }, only: %i[index show new edit create update destroy]

    # GET /users or /users.json
    def index
      @users = User.all.order(:email)
    end

    # GET /users/1 or /users/1.json
    def show; end

    # GET /users/new
    def new
      @user = User.new
    end

    # GET /users/1/edit
    def edit; end

    # POST /users or /users.json
    def create
      @user = User.new(user_params)

      respond_to do |format|
        if @user.save
          format.html { redirect_to admin_user_url(@user), notice: 'User was successfully created.' }
          format.json { render :show, status: :created, location: @user }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /users/1 or /users/1.json
    def update
      # Check if the currently logged-in user is trying to update their own role
      if @user == current_user && user_params[:role].present?
        user_params.delete(:role)
        flash[:alert] = 'You cannot change your own role.'
      end

      # Only update password if provided
      if user_params[:password].blank?
        user_params.delete(:password)
        user_params.delete(:password_confirmation)
        @user.update_without_password(user_params)
        return redirect_to admin_user_url(@user), notice: 'User was successfully updated.' if @user.valid?
      end

      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to admin_user_url(@user), notice: 'User was successfully updated.' }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /users/1 or /users/1.json
    def destroy
      if @user == current_user
        return redirect_to admin_users_url, alert: 'You cannot delete yourself.'
      end

      @user.destroy

      respond_to do |format|
        format.html { redirect_to admin_users_url, notice: 'User was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.fetch(:user, {}).permit(:email, :password, :password_confirmation, :role)
    end
  end
end
