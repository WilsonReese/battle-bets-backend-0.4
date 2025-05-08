class PoolMembershipsController < ApplicationController
    before_action :set_pool
    before_action :set_pool_membership, only: [:destroy, :update]
  
    # GET /pools/:pool_id/pool_memberships
    def index
      @memberships = @pool.sorted_memberships
      render json: @memberships.as_json(
        only: [:id, :is_commissioner, :created_at],
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

    def update
      if @membership.is_commissioner && params[:pool_membership][:is_commissioner] == false
        unless @membership.can_be_demoted?
          render json: { error: "A league must have at least one commissioner." }, status: :forbidden
          return
        end
      end

      if @membership.update(update_params)
        render json: @membership
      else
        render json: @membership.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /pools/:pool_id/pool_memberships/:id
    def destroy
      if @membership.is_commissioner
        render json: { error: "Commissioners cannot be removed." }, status: :forbidden
      else
        @membership.destroy
        head :no_content
      end
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

    def update_params
      params.require(:pool_membership).permit(:is_commissioner)
    end
end
