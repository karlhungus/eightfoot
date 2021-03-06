class IssuesController < ApplicationController
  before_action :set_project, only: [:index]
  before_action :set_issue, only: [:show, :edit, :update, :destroy]

  before_action :get_milestones

  def index
    # this is kind of ugly but it works
    @issue_map = {}
    @project.repositories.each do |repo|
      # TODO do this in batches
      if params[:milestone]
        update_issue_map @client.list_issues(repo.slug, milestone: params[:milestone]),repo
      else
        update_issue_map @client.list_issues(repo.slug),repo
      end
    end

    @issues = @project.issues.where( :gh_id => @issue_map.values.collect(&:id) )
  end

  def update_issue_map(issues,repo)
    issues.each do |issue|
      i = Issue.find_or_create_by(:gh_id => issue.id)
      i.project = @project
      i.repository = repo
      i.save if i.changed?

      @issue_map[i.id] = issue
    end
  end

  def get_milestones
    @milestones = @project.repositories.reduce([]) do |acc, repo|
      acc + @client.get("/repos/#{repo.slug}/milestones")
    end
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
  end

  # GET /issues/1/edit
  def edit
  end

  # PATCH/PUT /issues/1
  # PATCH/PUT /issues/1.json
  def update
    respond_to do |format|
      if @issue.update(issue_params)
        format.html { redirect_to @issue, notice: 'Issue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    @issue.destroy
    respond_to do |format|
      format.html { redirect_to issues_url }
      format.json { head :no_content }
    end
  end

  private
  def set_project
    @project = Project.find(params[:project_id])
  end


  # Use callbacks to share common setup or constraints between actions.
  def set_issue
    @issue = Issue.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def issue_params
    params[:issue]
  end
end
