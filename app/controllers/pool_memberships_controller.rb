class PoolMembershipsController < ApplicationController
    before_action :set_pool
    before_action :authenticate_user!, only: %i[index create destroy update]
    before_action :set_pool_membership, only: [:destroy, :update]
  
    # GET /pools/:pool_id/pool_memberships
    def index
      memberships = @pool.sorted_memberships
    
      render json: memberships.as_json(
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
      if params[:pool_membership].key?(:is_commissioner)
        unless authorized_to_update_membership?
          render json: { error: "Only commissioners can modify members." }, status: :forbidden
          return
        end
    
        if @membership.is_commissioner && params[:pool_membership][:is_commissioner] == false
          unless @membership.can_be_demoted?
            render json: { error: "A league must have at least one commissioner." }, status: :forbidden
            return
          end
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
      elsif authorized_to_remove_membership?
        @membership.destroy
        head :no_content
      else
        render json: { error: "Only commissioners can remove other users." }, status: :forbidden
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

    def authorized_to_remove_membership?
      current_user_membership = @pool.pool_memberships.find_by(user_id: current_user.id)
    
      @membership.user_id == current_user.id ||
        current_user_membership&.is_commissioner?
    end

    def authorized_to_update_membership?
      @pool.pool_memberships.find_by(user_id: current_user.id)&.is_commissioner?
    end
end
