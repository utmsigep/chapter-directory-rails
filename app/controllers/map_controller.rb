# frozen_string_literal: true

class MapController < ApplicationController
  def index
    @districts = District.order(:position)
  end

  def map_data
    @chapters = Chapter.where('status = ?', 1).order(:name)
    @chapters = Chapter.search(params[:q]) unless params[:q].blank?
    @chapters = District.find(params[:district_id]).chapters.where('status = ?', 1) unless params[:district_id].blank?
  end
end
