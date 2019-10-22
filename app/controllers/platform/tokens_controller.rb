class Platform::TokensController < PlatformController
  def create
    user      = current_platform.users.find_by!(public_id: params[:user_id])
    jwt_token = JwtUserTokenFactory.build(user, current_platform)
    token     = jwt_token.generate
    render json: Platform::TokenPresenter.new(token), status: :created
  end
end
