# frozen_string_literal: true

class MapController < ApplicationController
  def index
    @districts = District.order(:position)
  end

  def map_data
    @chapters = Chapter.active.order(:name)
    @chapters = Chapter.search(params[:q]) unless params[:q].blank?
    @chapters = District.find(params[:district_id]).chapters.active unless params[:district_id].blank?
    respond_to do |format|
      format.json { render json: @chapters }
    end
  end
end
