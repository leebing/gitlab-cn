class GroupsController < Groups::ApplicationController
  include IssuesAction
  include MergeRequestsAction

  skip_before_action :authenticate_user!, only: [:show, :issues, :merge_requests]
  respond_to :html
  before_action :group, except: [:new, :create]

  # Authorize
  before_action :authorize_read_group!, except: [:show, :new, :create, :autocomplete]
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects]
  before_action :authorize_create_group!, only: [:new, :create]

  # Load group projects
  before_action :load_projects, except: [:new, :create, :projects, :edit, :update, :autocomplete]
  before_action :event_filter, only: :show

  layout :determine_layout

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    @group.name = @group.path.dup unless @group.name

    if @group.save
      @group.add_owner(current_user)
      redirect_to @group, notice: "群组 '#{@group.name}' 创建成功。"
    else
      render action: "new"
    end
  end

  def show
    @last_push = current_user.recent_push if current_user
    @projects = @projects.includes(:namespace)

    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end

      format.atom do
        load_events
        render layout: false
      end
    end
  end

  def edit
  end

  def projects
    @projects = @group.projects.page(params[:page])
  end

  def update
    if @group.update_attributes(group_params)
      redirect_to edit_group_path(@group), notice: "群组 '#{@group.name}' 更新成功。"
    else
      render action: "edit"
    end
  end

  def destroy
    DestroyGroupService.new(@group, current_user).execute

    redirect_to root_path, alert: "群组 '#{@group.name}' 被成功删除。"
  end

  protected

  def group
    @group ||= Group.find_by(path: params[:id])
  end

  def load_projects
    @projects ||= ProjectsFinder.new.execute(current_user, group: group).sorted_by_activity.non_archived
  end

  def project_ids
    @projects.pluck(:id)
  end

  # Dont allow unauthorized access to group
  def authorize_read_group!
    unless @group and (@projects.present? or can?(current_user, :read_group, @group))
      if current_user.nil?
        return authenticate_user!
      else
        return render_404
      end
    end
  end

  def authorize_create_group!
    unless can?(current_user, :create_group, nil)
      return render_404
    end
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'application'
    elsif [:edit, :update, :projects].include?(action_name.to_sym)
      'group_settings'
    else
      'group'
    end
  end

  def group_params
    params.require(:group).permit(:name, :description, :path, :avatar, :public)
  end

  def load_events
    @events = Event.in_projects(project_ids)
    @events = event_filter.apply_filter(@events).with_associations
    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
