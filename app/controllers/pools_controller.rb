class PoolsController < ApplicationController
    before_action :set_pool, only: %i[show update destroy]
    before_action :authenticate_user!, only: %i[index]
  
    # GET /pools
    def index
      @pools = current_user.pools
  
      render json: @pools
    end
  
    # GET /pools/:id
    def show
      render json: @pool
    end
  
    # POST /pools
    def create
      @pool = Pool.new(pool_params)
  
      if @pool.save
        render json: @pool, status: :created, location: @pool
      else
        render json: @pool.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /pools/:id
    def update
      if @pool.update(pool_params)
        render json: @pool
      else
        render json: @pool.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /pools/:id
    def destroy
      @pool.destroy
    end
  
    private
  
    def set_pool
      @pool = Pool.find(params[:id])
    end
  
    def pool_params
      params.require(:pool).permit(:name)
    end
end

