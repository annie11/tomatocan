class UsersController < ApplicationController
  layout :resolve_layout

  before_action :set_user, except: [:new, :index, :userswithmerch, :youtubers, :create, :stripe_callback ]
  before_action :check_outstandingagreements, except: [:new, :index, :create, :approveagreement, :declineagreement ]
  before_action :authenticate_user!, only: [:edit, :update ]
#  before_filter :correct_user,   only: [:edit, :update, :managesales] Why did I comment this out, was I displaying cryptic error messages
  
  def index
    userswithpic = User.where( "profilepic SIMILAR TO '%(jpg|gif|tif|png|jpeg|GIF|JPG|JPEG|TIF|PNG)'
       OR (profilepicurl SIMILAR TO 'http%' AND 
       profilepicurl SIMILAR TO '%(jpg|gif|tif|png|jpeg|GIF|JPG|JPEG|TIF|PNG)%') ")
    @users = userswithpic.paginate(:page => params[:page], :per_page => 32)
  end

  def youtubers
    userswithyoutube = User.where("LENGTH(youtube1) < ? AND LENGTH(youtube1) > ?", 20, 4)
    usersvidorder = userswithyoutube.order('updated_at DESC')
    @youtubers = usersvidorder.paginate(:page => params[:page], :per_page => 32)
  end
  def userswithmerch
    userswmerch = User.joins(:merchandises).distinct
    merchorder = userswmerch.order('updated_at DESC')
    @merchusers = merchorder.paginate(:page => params[:page], :per_page => 32)
  end

  def show
#    @redirecturl = "https://connect.stripe.com/oauth/authorize?response_type=code&client_id=" + STRIPE_CONNECT_CLIENT_ID + "&scope=read_write"
    @books = @user.books
    @numusrgroups = 0 
    if user_signed_in?
      currusergroups = Group.where("user_id = ?", current_user.id)
      @usrgrpnameid = []
      currusergroups.find_each do |group|
        @usrgrpnameid <<  [group.name, group.id] 
      end 
      @numusrgroups = currusergroups.count 
      if current_user.stripeid.present?
#        @account = Stripe::Account.retrieve("#{@user.stripeid.to_s}") 
#        @balance = Stripe::Balance.retrieve("#{@user.stripeid.to_s}") # We dont 
      end
    end 

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end
  def about
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end
  def agreetopartner 
    @agreement = Agreement.new
    @agreement.update_attribute(:group_id, params[:currgroupid]) 
    @agreement.update_attribute(:user_id, params[:userid])
    redirect_to user_profile_path
  end

  def eventlist
    currtime = Time.now
    rsvps = Event.where('id IN (SELECT event_id FROM rsvpqs WHERE rsvpqs.user_id = ?)', @user.id)
    @rsvpevents = rsvps.where( "start_at > ?", currtime ) 
    @events = Event.where( "start_at > ? AND usrid = ?", currtime, @user.id )
    respond_to do |format|
      format.html 
      format.json { render json: @user }
    end
  end
  def pastevents
    currtime = Time.now
    @events = Event.where( "start_at < ? AND usrid = ?", currtime, @user.id )
    rsvps = Event.where('id IN (SELECT event_id FROM rsvpqs WHERE rsvpqs.user_id = ?)', @user.id)
    @rsvpevents = rsvps.where( "start_at < ?", currtime ) 
    respond_to do |format|
      format.html 
      format.json { render json: @user }
    end
  end
  def groups
    @groups = Group.where( "user_id = ?", @user.id )
    respond_to do |format|
      format.html 
      format.json { render json: @user }
    end
  end
  def perks
    @perks = Merchandise.where( "user_id = ?", @user.id )
    respond_to do |format|
      format.html 
      format.json { render json: @user }
    end
  end
  def profileinfo
#    @user.updating_password = false
    respond_to do |format|
      format.html # profileinfo.html.erb
      format.json { render json: @user }
    end
  end
  def changepassword
    respond_to do |format|
      format.html # profileinfo.html.erb
      format.json { render json: @user }
    end
  end
  def readerprofileinfo
    respond_to do |format|
      format.html # readerprofileinfo.html.erb
      format.json { render json: @user }
    end
  end
  def editbookreview
    respond_to do |format|
      format.html # editbookreview.html.erb
      format.json { render json: @user }
    end
  end
  def editauthorreview
    respond_to do |format|
      format.html # editauthorreview.html.erb
      format.json { render json: @user }
    end
  end

  def followers
    @title = "Followers"
    @user  = User.find(params[:id])
    @users = @user.follower.paginate(page: params[:page])
    render 'followerspage'
  end

  def following
    @title = "Following"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'followingpage'
  end

  # GET /users/1.json
  def booklist
    @books = @user.books
    respond_to do |format|
      format.html # booklist.html.erb
      format.json { render json: @user }
    end
  end
  def movielist
    @movies = @user.movies
    respond_to do |format|
      format.html # booklist.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new I don't think this is used
  def new
    @user = User.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit 76
  def edit
    @books = @user.books
    @book = current_user.books.build # if signed_in?
    @booklist = Book.where(:user_id => @user.id)
  end
  def movieedit
    @movies = @user.movies
    @movie = current_user.movies.build # if signed_in?
    @movielist = Movie.where(:user_id => @user.id)
  end

  def approveagreement  #called from button on
    current_user.approve_agreement(params[:agreeid]) #this isnt where we want to redirect
    redirect_to user_profile_path(current_user.permalink)
  end
  def declineagreement  #called from button on
    current_user.decline_agreement(params[:agreeid])  
    redirect_to user_profile_path(current_user.permalink)
  end
  def markfulfilled  #called from button on author dashboard
    current_user.mark_fulfilled(params[:purchid])  
    redirect_to user_dashboard_path(current_user.permalink)
  end

  def dashboard
    @user.calcdashboard
    @monthperkinfo = @user.monthperkinfo
    @monthbookinfo = @user.monthbookinfo
    @incomeinfo = @user.incomeinfo
    @salebyfiletype = @user.salebyfiletype
    @salebyperktype = @user.salebyperktype
    @totalinfo = @user.totalinfo
    @purchasesinfo = @user.purchasesinfo
  end

  def stripe_callback
    options = {
      site: 'https://connect.stripe.com',
      authorize_url: '/oauth/authorize',
      token_url: '/oauth/token'
    }
    code = params[:code]
    if Rails.env.development? || Rails.env.test?
      client = OAuth2::Client.new(STRIPE_CONNECT_CLIENT_ID, STRIPE_SECRET_KEY, options)
    else
      client = OAuth2::Client.new(ENV['STRIPE_CONNECT_CLIENT_ID'], ENV['STRIPE_SECRET_KEY'], options)
    end

    @resp = client.auth_code.get_token(code, :params => {:scope => 'read_write'})
    @access_token = @resp.token
    current_user.update!(stripeid: @resp.params["stripe_user_id"]) if @resp
    flash[:notice] = "Your account has been successfully created and is ready to process payments!"
  end
  
  # POST /users.json 
  def create
    @user = User.new(user_params)
#    @user.latitude = request.location.latitude #geocoder has become piece of junk
#    @user.longitude = request.location.longitude
    if @user.save
      @user.get_youtube_id
      sign_in @user
      redirect_to user_profileinfo_path(current_user.permalink)
    else
        redirect_to new_user_signup_path, danger: signup_error_message
        @user.errors.clear
    end
  end

  # PUT /users/1.json
  def update
    if @user.update_attributes(user_params)
      @user.get_youtube_id
      bypass_sign_in @user
      redirect_to user_profile_path(current_user.permalink)
    else
#      flash[:notice] = flash[:notice].to_a.concat resource.errors.full_messages
      #redirect_to user_profileinfo_path(current_user.permalink), :notice => "Your profile was not saved. Check character counts or filetype for profile picture."
        
      if params[:user][:on_password_reset] == "changepassword"
        redirect_to user_changepassword_path(current_user.permalink), danger: update_error_message
      else
        redirect_to user_profileinfo_path(current_user.permalink), danger: update_error_message
      end
      @user.errors.clear
    end  
  end
  
  def facebook
    @facebook = from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |facebook|
      facebook.provider = auth.provider
      facebook.uid = auth.uid
      facebook.name = auth.info.name
      facebook.oauth_token = auth.credentials.token
      facebook.oauth_expires_at = Time.at(auth.credentials.expires_at)
      facebook.save!
    end
  end


  private

    def user_params
      params.require(:user).permit(:permalink, :name, :email, :password, 
        :about, :author, :password_confirmation, :genre1, :genre2, :genre3, 
        :twitter, :title, :profilepic, :profilepicurl, :remember_me, 
        :facebook, :address, :latitude, :longitude, :youtube1, :youtube2, 
        :youtube3, :videodesc1, :videodesc2, :videodesc3, :updating_password, 
        :agreeid, :purchid, :bannerpic, :on_password_reset )
    end

    def resolve_layout
      case action_name
      when "index", "youtubers", "userswithmerch", "stripe_callback"
        'application'
      when "profileinfo", "readerprofileinfo", "changepassword"
        'editinfotemplate'
      else
        'userpgtemplate'
      end
    end

    def check_outstandingagreements
      if user_signed_in?
        allmyagreements = Agreement.where('(user_id = ?)', current_user.id)
        @mynullagreements = allmyagreements.where("approved IS NULL" )
      end
    end

    def set_user 
      @user = User.find_by_permalink(params[:permalink]) || current_user
      if @user.merchandises.any? 
        noexpiredmerch = @user.merchandises.where("deadline > ? OR deadline IS NULL", Date.today)
        deadlineorder = noexpiredmerch.order('deadline IS NULL, deadline ASC')
        @sidebarmerchandise = deadlineorder.all[0..0] + deadlineorder.all[1..-1].sort_by(&:price)
      end 
    end
     # returns a string of error messages for the user signup page
    def signup_error_message
       msg = ""
        if @user.errors.messages[:name].present?
          msg += ("Name " + @user.errors.messages[:name][0] + "\n")
        end
        if @user.errors.messages[:email].present?
          @user.errors.messages[:email].each do |email| 
            msg += ("Email " + email + "\n")
          end
        end
        if @user.errors.messages[:permalink].present?
          msg += ("Permalink " + @user.errors.messages[:permalink][0] + "\n")
        end
        if @user.errors.messages[:password].present?
          msg += ("Password " + @user.errors.messages[:password][0] + "\n")
        end
        
        return msg
    end

    def update_error_message
      msg = ""
      if @user.errors.messages[:name].present?
        msg += ("Name " + @user.errors.messages[:name][0] + "\n")
      end
      if @user.errors.messages[:email].present?
        msg += ("Email " + @user.errors.messages[:email][0] + "\n")
      end
      if @user.errors.messages[:permalink].present?
        msg += ("URL handle " + @user.errors.messages[:permalink][0] + "\n")
      end
      if @user.errors.messages[:password_confirmation].present?
        msg += ( "Passwords do not match \n")
      end
      if @user.errors.messages[:password].present?
        msg += ("Password " + @user.errors.messages[:password][0] + "\n")
      end
      if @user.errors.messages[:twitter].present?
        msg += ("Twitter handle " + @user.errors.messages[:twitter][0] + "\n")
      end

      return msg
    end

end