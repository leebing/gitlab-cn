module DiffHelper
  def diff_view
    params[:view] == 'parallel' ? 'parallel' : 'inline'
  end

  def allowed_diff_size
    if diff_hard_limit_enabled?
      Commit::DIFF_HARD_LIMIT_FILES
    else
      Commit::DIFF_SAFE_FILES
    end
  end

  def allowed_diff_lines
    if diff_hard_limit_enabled?
      Commit::DIFF_HARD_LIMIT_LINES
    else
      Commit::DIFF_SAFE_LINES
    end
  end

  def safe_diff_files(diffs, diff_refs)
    lines = 0
    safe_files = []
    diffs.first(allowed_diff_size).each do |diff|
      lines += diff.diff.lines.count
      break if lines > allowed_diff_lines
      safe_files << Gitlab::Diff::File.new(diff, diff_refs)
    end
    safe_files
  end

  def diff_hard_limit_enabled?
    # Enabling hard limit allows user to see more diff information
    if params[:force_show_diff].present?
      true
    else
      false
    end
  end

  def generate_line_code(file_path, line)
    Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
  end

  def unfold_bottom_class(bottom)
    (bottom) ? 'js-unfold-bottom' : ''
  end

  def unfold_class(unfold)
    (unfold) ? 'unfold js-unfold' : ''
  end

  def diff_line_content(line)
    if line.blank?
      " &nbsp;".html_safe
    else
      line.html_safe
    end
  end

  def line_comments
    @line_comments ||= @line_notes.select(&:active?).group_by(&:line_code)
  end

  def organize_comments(type_left, type_right, line_code_left, line_code_right)
    comments_left = comments_right = nil

    unless type_left.nil? && type_right == 'new'
      comments_left = line_comments[line_code_left]
    end

    unless type_left.nil? && type_right.nil?
      comments_right = line_comments[line_code_right]
    end

    [comments_left, comments_right]
  end

  def inline_diff_btn
    diff_btn('内嵌', 'inline', diff_view == 'inline')
  end

  def parallel_diff_btn
    diff_btn('并排对比', 'parallel', diff_view == 'parallel')
  end

  def submodule_link(blob, ref, repository = @repository)
    tree, commit = submodule_links(blob, ref, repository)
    commit_id = if commit.nil?
                  Commit.truncate_sha(blob.id)
                else
                  link_to Commit.truncate_sha(blob.id), commit
                end

    [
      content_tag(:span, link_to(truncate(blob.name, length: 40), tree)),
      '@',
      content_tag(:span, commit_id, class: 'monospace'),
    ].join(' ').html_safe
  end

  def commit_for_diff(diff)
    if diff.deleted_file
      @base_commit || @commit.parent || @commit
    else
      @commit
    end
  end

  def diff_file_html_data(project, diff_commit, diff_file)
    {
      blob_diff_path: namespace_project_blob_diff_path(project.namespace, project,
                                                       tree_join(diff_commit.id, diff_file.file_path))
    }
  end

  def editable_diff?(diff)
    !diff.deleted_file && @merge_request && @merge_request.source_project
  end

  private

  def diff_btn(title, name, selected)
    params_copy = params.dup
    params_copy[:view] = name

    # Always use HTML to handle case where JSON diff rendered this button
    params_copy.delete(:format)

    link_to url_for(params_copy), id: "#{name}-diff-btn", class: (selected ? 'btn active' : 'btn') do
      title
    end
  end
end
