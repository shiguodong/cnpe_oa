class EntretainsController < ApplicationController
  skip_before_action :authenticate_user!,:only => [:auddit_from_mail]
  before_action :set_entretain, only: [:show,:auddit,:auddit_from_mail]

  # GET /entretains
  # GET /entretains.json
  def index
  	if params[:q]=="submit"
  		@entretains = current_user.entretains

  	elsif params[:q]=="report"
        @entretains =Entretain.where(["reporter_id=?",current_user.id])
    else
        @entretains = Entretain.where(["user_id=? or reporter_id=?", current_user.id,current_user.id])
    end
  end

  # GET /entretains/1
  # GET /entretains/1.json
  def show
  end

  # GET /entretains/new
  def new
    @entretain = Entretain.new(fee: nil, entertained_num: nil)
  end



  # POST /entretains
  # POST /entretains.json
  def create
    @entretain = Entretain.new(entretain_params)
    @entretain.content = params["content"]
    @entretain.user_id = current_user.id
    @entretain.audit if @entretain.reporter_id && @entretain.reporter_id!=current_user.id
    if @entretain.reporter_id && @entretain.reporter_id==current_user.id
       @entretain.aasm_state="auditting"
       @entretain.accept 
    end

    

    respond_to do |format|
      if @entretain.save
        format.html { redirect_to @entretain, notice: '宴请单申请成功，等待审核.' }
        format.json { render action: 'show', status: :created, location: @entretain }
      else
        format.html { render action: 'new' }
        format.json { render json: @entretain.errors, status: :unprocessable_entity }
      end
    end
  end
  def auddit
  	 @entretain.send(params[:e])

  	 redirect_to entretains_url if  @entretain.save
  end

  def auddit_from_mail
  	 return redirect_to entretains_url , notice: '该宴请已经被审批过了 :)'  if ["rejectting","last_acceptting","last_rejectting","finished"].include? @entretain.aasm_state
     email =  Base64.decode64(params["token"])
     motion =  Base64.decode64(params["e"])
     user = User.find_by(email: email)

     return render :text => "error" unless user 
     return render :text => "您没有审核权限 " unless  [@entretain.reporter_id, @entretain.last_reporter_id].include? user.id 
     sign_in user  

     @entretain.send(motion)
     redirect_to entretains_url if  @entretain.save
  end

  def statistics
  	@applies = Entretain.where(aasm_state: ["last_acceptting","acceptting"])
  	@applies = @applies.where("title=?",params[:name]) unless params["name"].blank?
    #	@applies = @applies.where("status=?",params[:status]) unless params["status"].blank?
  	@applies = @applies.where("created_at>=?",params[:start_at]) unless params["start_at"].blank? || params["start_at"].to_time.blank?
  	@applies = @applies.where("created_at<=?",params[:end_at]) unless params["end_at"].blank? || params["end_at"].to_time.blank?
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entretain
      @entretain = Entretain.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def entretain_params
      params.require(:entretain).permit(:user_id, :title, :fee, :location,:last_reporter_id, :content, :reporter_id,:num,:attache)
    end
end
