class UsersController < ApplicationController
  def index
    @q = User.ransack(params[:q])
    @users = @q.result(distinct: true).order(created_at: :desc)
    @daily_records = DailyRecord.all

    if params[:q].present? && params[:q][:name_cont].present?
      search_term = params[:q][:name_cont].downcase
      @users = User.where("lower(CONCAT(users.name->>'first', ' ', users.name->>'last')) LIKE ?", "%#{search_term}%")
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    redirect_to root_path, notice: 'User was successfully deleted.'
  end
end
