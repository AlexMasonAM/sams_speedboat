module  Api
  class SpeedboatsController < ApplicationController
    
    def index
      speedboats = Speedboat.all
      render json: speedboats.to_json
    end
    
    def show
      speedboat = Speedboat.find(params[:id])
      render json: speedboat.to_json
    end

    def create
      speedboat = Speedboat.new(speedboat_params)

      if speedboat.save
        render json: speedboat.to_json, location: [:api, speedboat], status: 201
      end
    end

    def update
      speedboat = Speedboat.find(params[:id])
      
      if speedboat.update_attributes(speedboat_params)
        render json: speedboat.to_json, status: 204
      else
        render json: speedboat.to_json
      end
    end

    def destroy
      speedboat = Speedboat.find(params[:id])
      speedboat.destroy
      render json: speedboat.to_json, status: 204
    end

    private
      def speedboat_params
        params.require(:speedboat).permit(:brand, :model_number, :image_url, :wholesale_price, :retail_price, :in_stock)
      end
  end
end