class PoolMembershipsController < ApplicationController
    before_action :set_pool
    before_action :set_pool_membership, only: :destroy
  
    # GET /pools/:pool_id/pool_memberships
    def index
      @memberships = @pool.pool_memberships.includes(:user)
      render json: @memberships.as_json(
        only: [:id, :is_commissioner],
        include: {
          user: {
            only: [:id, :first_name, :last_name, :username]
          }
        }
      )
    end
  
    # POST /pools/:pool_id/pool_memberships
    def create
      @membership = @pool.pool_memberships.new(pool_membership_params)
  
      if @membership.save
        render json: @membership, status: :created
      else
        render json: @membership.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /pools/:pool_id/pool_memberships/:id
    def destroy
      @membership.destroy
      head :no_content
    end
  
    private
  
    def set_pool
      @pool = Pool.find(params[:pool_id])
    end
  
    def set_pool_membership
      @membership = @pool.pool_memberships.find(params[:id])
    end
  
    def pool_membership_params
      params.require(:pool_membership).permit(:user_id)
    end
end
