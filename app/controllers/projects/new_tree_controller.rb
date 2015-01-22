#encoding: utf-8
class Projects::NewTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :authorize_push_code!

  def show
  end

  def update
    file_path = File.join(@path, File.basename(params[:file_name]))
    result = Files::CreateService.new(@project, current_user, params, @ref, file_path).execute

    if result[:status] == :success
      flash[:notice] = "你的更改已成功提交"
      redirect_to project_blob_path(@project, File.join(@ref, file_path))
    else
      flash[:alert] = result[:message]
      render :show
    end
  end
end
