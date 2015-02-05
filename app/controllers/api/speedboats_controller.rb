module  Api
  class SpeedboatsController < ApplicationController
    
    def index
      speedboats = Speedboat.all
      render json: speedboats.to_json
    end

  end
end