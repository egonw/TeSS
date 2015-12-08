class MaterialsController < ApplicationController
  require 'bread_crumbs'

  before_action :set_material, only: [:show, :edit, :update, :destroy]

  #sets @search_params, @facet_params, and @page 
  before_action :set_params, :only => :index

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :check_title] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_filter :authenticate_user!, except: [:index, :show, :check_title]

  # Should prevent forgery errors for JSON posts.
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  include TeSS::BreadCrumbs

  # GET /materials
  # GET /materials?q=queryparam
  # GET /materials.json
  # GET /materials.json?q=queryparam

  @@facet_fields = %w( scientific_topic target_audience keywords licence difficulty_level authors contributors )

  helper 'search'

  def index
    @facet_fields = @@facet_fields
    if SOLR_ENABLED
      @materials = solr_search(Material, @search_params, @@facet_fields, @facet_params, @page, @sort_by)
    else
      @materials = Material.all
    end
    respond_to do |format|
      format.json { render json: @materials.results }
      format.html
    end
  end

  def search query
    @materials = Material.search { fulltext query } 
  end 


  # GET /materials/1
  # GET /materials/1.json
  def show
  end

  # GET /materials/new
  def new
    @material = Material.new
  end

  # GET /materials/1/edit
  def edit
  end

  # POST /materials/check_title
  # POST /materials/check_title.json
  def check_title
    title = params[:title]
    if title
      @material = Material.find_by_title(title)
      if @material
        respond_to do |format|
          format.html { redirect_to @material }
          #format.json { render json: @material }
          format.json { render :show, location: @material }
        end
      else
        respond_to do |format|
          format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
          format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
        end
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
      end
    end
  end

  # POST /materials
  # POST /materials.json
  def create
    @material = Material.new(material_params)

    respond_to do |format|
      if @material.save
        @material.create_activity :create
        current_user.materials << @material
        format.html { redirect_to @material, notice: 'Material was successfully created.' }
        format.json { render :show, status: :created, location: @material }
      else
        format.html { render :new }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /materials/1
  # PATCH/PUT /materials/1.json
  def update
    respond_to do |format|
      material_params
      if @material.update(material_params)
        @material.create_activity :update, owner: current_user
        format.html { redirect_to @material, notice: 'Material was successfully updated.' }
        format.json { render :show, status: :ok, location: @material }
      else
        format.html { render :edit }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /materials/1
  # DELETE /materials/1.json
  def destroy
    @material.create_activity :destroy, owner: current_user
    @material.destroy
    respond_to do |format|
      format.html { redirect_to materials_url, notice: 'Material was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material
      @material = Material.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def material_params
      params.require(:material).permit(:title, :url, :short_description, :long_description, :doi, 
        :remote_updated_date, :remote_created_date,  :remote_updated_date, :package_ids, :content_provider_id)
    end

    def set_params
      params.permit(:q, :page, :sort, @@facet_fields, @@facet_fields.map{|f| "#{f}_all"})
      @search_params = params[:q] || ''
      @facet_params = {}
      @sort_by = params[:sort]
      @@facet_fields.each {|facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
      @page = params[:page] || 1
    end

end
