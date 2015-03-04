class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :signed_in_user, only: [:edit, :update]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy
  # GET /users
  # GET /users.json
  def index
    # @users = User.all
    @users = User.page(params[:page]).per(1)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    if !@user.is_actived
      flash[:danger] = "您的账号还未激活，请激活之后再使用！"
    end
  end

  # GET /users/new
  def new
    if !signed_in?
      @user = User.new
    else
      flash[:warning] = "您已登录，请退出后再进行注册操作！"
      redirect_to current_user
    end
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    
    @user.name = @user.email.split("@")[0]
    @user.active_code = rand(Time.now.to_i).to_s
    @user.is_actived = false
    @user.admin  = false
    respond_to do |format|
      if @user.save
        UserMailer.signup_confirm_email(@user).deliver
        sign_in @user

        format.html { redirect_to @user, notice: '注册成功，感谢您注册本站，请登录注册邮箱激活您的账户！' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.is_actived
        if @user.update_attributes(user_params)
          format.html { redirect_to @user, notice: '个人信息更新成功！' }
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      else
        flash[:danger] = "账号未激活，无法更新个人信息！"
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: '删除用户成功!' }
      format.json { head :no_content }
    end
  end

  def active
    @user = User.find_by(name:params[:name])
    if @user != nil && !@user.is_actived && @user.active_code == params[:active_code]
      @user.update_attribute(:is_actived, true)
      flash[:success] = "恭喜您，您已经成功激活了您的账户！"
    elsif @user != nil && @user.is_actived
      flash[:warning] = "您的账户已经处于激活状态，请勿重复激活！"
    else
      flash[:danger] = "激活失败！"
    end

    redirect_to root_path
  end

  def resend_active_mail
    UserMailer.signup_confirm_email(@user).deliver
    flash[:success] = "激活邮件发送成功，请前往注册邮箱查看！"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "请登录后再进行此操作！"
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, 
                                   :email, 
                                   :password, 
                                   :password_confirmation)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
