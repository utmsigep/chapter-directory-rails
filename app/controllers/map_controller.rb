# frozen_string_literal: true

class MapController < ApplicationController
  def index
    @districts = District.order(:position)
    @regions = Region.where('status = ?', 1).order(:position)
  end

  def map_data
    @chapters = Chapter.order(:name)
    @chapters = Chapter.search(params[:q]) unless params[:q].blank?
    @chapters = District.find(params[:district_id]).chapters.where('status = ?', 1) unless params[:district_id].blank?
    @chapters = Region.find(params[:region_id]).chapters.where('status = ?', 1) unless params[:region_id].blank?
  end
end
