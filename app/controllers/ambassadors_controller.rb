class AmbassadorsController < ApplicationController
  # anyone can fetch this list
  def index
    render json: AMBASSADOR_LABELS.map { |key, label|
      {
        value: key,        # enum key
        label: label       # human‑readable
      }
    }
  end
end