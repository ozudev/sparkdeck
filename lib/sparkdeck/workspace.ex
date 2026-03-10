defmodule Sparkdeck.Workspace do
  import Ecto.Query, warn: false

  alias Sparkdeck.Briefs.Generator
  alias Sparkdeck.Repo
  alias Sparkdeck.Workspace.{GeneratedBrief, Project}

  def list_projects do
    from(p in Project, order_by: [desc: p.updated_at, desc: p.id])
    |> Repo.all()
  end

  def get_project!(id), do: Repo.get!(Project, id)

  def get_project_with_latest_brief!(id) do
    project = get_project!(id)
    {project, latest_brief(id)}
  end

  def latest_brief(project_id) do
    from(
      b in GeneratedBrief,
      where: b.project_id == ^project_id,
      order_by: [desc: b.inserted_at, desc: b.id],
      limit: 1
    )
    |> Repo.one()
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def update_project_status(%Project{} = project, status) do
    project
    |> Ecto.Changeset.change(status: status)
    |> Repo.update()
  end

  def duplicate_project(%Project{} = project) do
    attrs = %{
      name: "#{project.name} Copy",
      idea: project.idea,
      target_customer: project.target_customer,
      problem: project.problem,
      constraints: project.constraints,
      product_already_exists: project.product_already_exists,
      status: "draft"
    }

    with {:ok, duplicate} <- create_project(attrs) do
      case latest_brief(project.id) do
        nil -> {:ok, duplicate}
        %GeneratedBrief{} = brief -> duplicate_with_brief(duplicate, brief)
      end
    end
  end

  def generate_preview(project_attrs), do: Generator.generate_preview(project_attrs)

  def save_preview(project_params, brief_attrs, raw_response, model) do
    Repo.transaction(fn ->
      with {:ok, project} <- create_project(project_params),
           brief_attrs <-
             brief_attrs
             |> Map.put(:project_id, project.id)
             |> Map.put(:raw_response, raw_response)
             |> Map.put(:model, model)
             |> Map.put(:prompt_version, Application.fetch_env!(:sparkdeck, :llm_prompt_version)),
           {:ok, _brief} <-
             %GeneratedBrief{}
             |> GeneratedBrief.changeset(brief_attrs)
             |> Repo.insert(),
           {:ok, project} <- update_project_status(project, "generated") do
        project
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def generate_brief(%Project{} = project), do: Generator.generate_project_brief(project)

  def regenerate_section(%Project{} = project, section),
    do: Generator.regenerate_section(project, section)

  defp duplicate_with_brief(project, brief) do
    attrs =
      brief
      |> Map.from_struct()
      |> Map.take([
        :summary,
        :icp_analysis,
        :icp_recommendations,
        :overlooked_segments,
        :pain_points,
        :value_proposition,
        :mvp_features,
        :alternate_approaches,
        :landing_page_content,
        :creative_direction,
        :interview_questions,
        :interview_signals,
        :validation_checklist,
        :go_to_market,
        :fundraising_plan,
        :risks,
        :next_steps,
        :raw_response,
        :model,
        :prompt_version
      ])
      |> Map.put(:project_id, project.id)

    %GeneratedBrief{}
    |> GeneratedBrief.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, _brief} ->
        update_project_status(project, "generated")
        {:ok, project}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
