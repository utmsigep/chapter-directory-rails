class Admin::ChaptersController < ApplicationController
  before_action :set_chapter, only: %i[ show edit update destroy ]

  # GET /chapters or /chapters.json
  def index
    @chapters = Chapter.order(:name)
    @missing_region = Chapter.where(region: nil, status: true)
    @missing_district = Chapter.where(district: nil, status: true)
    if params[:format] == 'csv'
      send_data Chapter.generate_csv, filename: 'chapters.csv'
    end
  end

  # GET /chapters/1 or /chapters/1.json
  def show
    render json: [@chapter] if params[:wrap] == 'true'
  end

  # GET /chapters/new
  def new
    @chapter = Chapter.new
  end

  # GET /chapters/1/edit
  def edit
  end

  # POST /chapters or /chapters.json
  def create
    @chapter = Chapter.new(chapter_params)

    respond_to do |format|
      if @chapter.save
        format.html { redirect_to admin_chapter_url(@chapter), notice: "Chapter was successfully created." }
        format.json { render :show, status: :created, location: @chapter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chapters/1 or /chapters/1.json
  def update
    respond_to do |format|
      if @chapter.update(chapter_params)
        format.html { redirect_to admin_chapter_url(@chapter), notice: "Chapter was successfully updated." }
        format.json { render :show, status: :ok, location: @chapter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chapters/1 or /chapters/1.json
  def destroy
    @chapter.destroy

    respond_to do |format|
      format.html { redirect_to admin_chapters_url, notice: "Chapter was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def import
  end

  def do_import
    uploaded_file = params[:file]
    raise "No file provided" if uploaded_file.nil?
    csv = CSV.parse(uploaded_file.read, headers: true)

    # Create Regions and Districts if Missing
    csv.each do |row|
      if row['region']
        region = Region.find_or_create_by(short_name: row['region'])
        region.name = "Region #{row['region']}" if region.name.nil?
        region.short_name = "#{row['region']}" if region.short_name.nil?
        region.position = row['region'].to_i if region.position == 0
        region.save!
      end

      if row['district']
        district = District.find_or_create_by(short_name: row['district'])
        district.name = "District #{row['district']}" if district.name.nil?
        district.short_name = "#{row['district']}" if district.short_name.nil?
        district.position = row['district'].to_i if district.position == 0
        district.save!
      end
    end

    # Process Chapter Updates
    csv.each do |row|
      chapter = Chapter.find_or_create_by(name: row['name'])
      chapter.name = row['name']
      chapter.slc = row['slc'] unless row['slc'].nil?
      chapter.institution_name = row['institution_name'] unless row['institution_name'].nil?
      chapter.location = row['location'] unless row['location'].nil?
      chapter.latitude = row['latitude'] unless row['latitude'].nil?
      chapter.longitude = row['longitude'] unless row['longitude'].nil?
      chapter.website = row['website'] unless row['website'].nil?
      chapter.status = row['status'] unless row['status'].nil?
      chapter.district = District.find_by(short_name: row['district']) unless row['district'].nil?
      chapter.district = District.find(row['district_id']) unless row['district_id'].nil?
      chapter.region = Region.find_by(short_name: row['region']) unless row['region'].nil?
      chapter.region = Region.find(row['region_id']) unless row['region_id'].nil?
      chapter.save!
    end

    flash[:notice] = 'Upload complete!'
    redirect_to(admin_chapters_url)
  rescue CSV::MalformedCSVError => error
    flash[:error] = "Parsing Error: #{error}"
    redirect_to(admin_chapters_import_url)
  rescue => error
    flash[:error] = "#{error}"
    redirect_to(admin_chapters_import_url)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chapter
      @chapter = Chapter.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chapter_params
      params.fetch(:chapter, {}).permit(:name, :institution_name, :location, :website, :slc, :status, :region_id, :district_id, :longitude, :latitude)
    end
end
