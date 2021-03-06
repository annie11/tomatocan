class PhasesController < ApplicationController
  before_action :set_phase, only: [:storytellerperks, :edit, :destroy, :show, :patronperk, :update]
  layout :resolve_layout

  # GET /phases
  def index
    if user_signed_in?
      currentuserid = current_user.id

      currusergroupstripe = Group.where("user_id = ? AND stripeid IS NOT NULL", currentuserid)
      @usrgrpnameidstripe = []
      currusergroupstripe.find_each do |group|
        @usrgrpnameidstripe << [group.name, group.id] 
      end 
      @numusrgroupstripe = currusergroupstripe.count 
      
      @groupswithoutstripe = []
      currusergroupsnostripe = Group.where("user_id = ? AND stripeid IS NULL", currentuserid)
      currusergroupsnostripe.each do |group|
        @groupswithoutstripe <<  {name: group.name, permalink: group.permalink, id: group.id} 
      end 
      @numusrgroupsnostripe = currusergroupsnostripe.count 
    end  
    threemonthago = Time.now - 3.months
    
    @agreedeclined=Agreement.joins(:group).where("user_id = ? AND agreements.created_at > ? 
      AND approved < ? ", currentuserid, threemonthago, '0002-01-01' )
#x = phase.where(id: Agreement.select("phase_id").where( group_id: Group.where("user_id = ?", current_user.id)) )
# x = all phases the user has already requested to affiliate with, over all of the user's groups.
# Don't display phases that user/group has already requested to affiliate with. However
#   if curr_user manages more than one group, all user's groups should be able to support the same phase

    #don't want 1 group to support 80 phases. 3 might be enough
#    numprojgroupsupports = Agreement.where("group_id = ?", @currgroup.id).count

    partner = []  #All phases available to be supported
#    active = Phase.where("deadline > ?", Time.now)
    active = Phase.all
    active.find_each do |phs|
      author = User.find(phs.user_id).name
      authorperm = User.find(phs.user_id).permalink
      partner <<  {name: phs.name, creator: author, authorpermalink: authorperm, mission: phs.mission, id: phs.id,
          permalink: phs.permalink, deadline: phs.deadline, phasepic: phs.phasepic} 
    end 
    @partnerphs = partner.sort_by{|e| e[:deadline]}
  end

  # GET /phases/1
  def show
    @merchandise = @phase.merchandises.order(price: :asc)
    @author = User.find(@phase.user_id)
    @groupid = params[:groupid] #if this phase was linked to from an organizations page
    if user_signed_in?
      currentuserid = current_user.id

      currusergroupstripe = Group.where("user_id = ? AND stripeid IS NOT NULL", currentuserid)
      @usrgrpnameidstripe = []
      currusergroupstripe.find_each do |group|
        @usrgrpnameidstripe << [group.name, group.id] 
      end 
      @numusrgroupstripe = currusergroupstripe.count 
      
      @groupswithoutstripe = []
      currusergroupsnostripe = Group.where("user_id = ? AND stripeid IS NULL", currentuserid)
      currusergroupsnostripe.find_each do |group|
        @groupswithoutstripe <<  {name: group.name, permalink: group.permalink, id: group.id} 
      end 
      @numusrgroupsnostripe = currusergroupsnostripe.count 
    end  
  end

  # GET /phases/new
  def new
    @phase = Phase.new
  end

  def edit
    @merchandise = @phase.merchandises.order(price: :asc)
    @perklist = Merchandise.where( "user_id = ?", current_user.id).where("phase_id != ?", @phase.id)
    #change to merch has belongs to many phase
    @merchandises = @phase.merchandises.build 
  end

  def create
    @phase = current_user.phases.build(phase_params)
    if @phase.save
      @phase.get_youtube_id
      redirect_to phase_storytellerperks_path(@phase.permalink), notice: 'phase was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    if @phase.update(phase_params)
      @phase.get_youtube_id
      @phase.update_attribute(:slug, @phase.permalink)
      redirect_to @phase, notice: 'Phase was successfully updated.'
    else
      render action: 'edit'
    end
  end

  private
    def set_phase
      if params[:id].present?
        @phase = Phase.friendly.find(params[:id])
      else
        @phase = Phase.find_by_permalink(params[:permalink])
      end
      @user = User.find(@phase.user_id)
      if @user.phases.any?
        @sidebarphase = @user.phases.order('deadline').last 
        @sidebarmerchandise = @sidebarphase.merchandises.order(price: :asc)
      end
    end

    # Only allow a trusted parameter "white list" through.
    def phase_params
      params.require(:phase).permit(:name, :user_id, :mission, :phasepic, :permalink, 
        :deadline, :why_classy, :youtube, :slug)
    end

    def resolve_layout
      case action_name
      when "show", "edit"
        'phasetemplate'
      else
        'application'
      end
    end
end
