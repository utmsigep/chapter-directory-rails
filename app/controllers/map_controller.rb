class MapController < ApplicationController
  def index
    @districts = District.order(:position)
    @regions = Region.order(:position)
  end

  def map_data
    @chapters = Chapter.order(:name)
    @chapters = Chapter.search(params[:q]) unless params[:q].blank?
    @chapters = District.find(params[:district_id]).chapters unless params[:district_id].blank?
    @chapters = Region.find(params[:region_id]).chapters unless params[:region_id].blank?
  end
end
