defmodule Sparkdeck.Briefs.Generator do
  alias Sparkdeck.Briefs.{BriefSchema, PromptBuilder}
  alias Sparkdeck.LLM.Client
  alias Sparkdeck.Repo
  alias Sparkdeck.Workspace
  alias Sparkdeck.Workspace.{GeneratedBrief, GenerationRun, Project}

  def generate_preview(project_attrs) when is_map(project_attrs) do
    project = struct(Project, atomize_keys(project_attrs))
    model = Application.fetch_env!(:sparkdeck, :llm_model)

    case Client.create_structured_output(
           PromptBuilder.full_brief_messages(project),
           BriefSchema,
           model: model
         ) do
      {:ok, %{parsed: parsed, raw_response: raw_response, model: response_model}} ->
        {:ok,
         %{
           brief_attrs: to_persistable_map(parsed),
           raw_response: raw_response,
           model: response_model
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp atomize_keys(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} -> {k, v}
    end)
  rescue
    _ -> map
  end

  defp to_persistable_map(%BriefSchema{} = brief) do
    brief
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.into(%{}, fn
      {k, %{__struct__: _} = v} -> {k, embedded_to_map(v)}
      {k, v} when is_list(v) -> {k, Enum.map(v, &maybe_embedded_to_map/1)}
      {k, v} -> {k, v}
    end)
  end

  def generate_project_brief(%Project{} = project) do
    prompt_version = Application.fetch_env!(:sparkdeck, :llm_prompt_version)
    model = Application.fetch_env!(:sparkdeck, :llm_model)

    {:ok, run} =
      create_generation_run(project, %{
        section: "full_brief",
        status: "running",
        provider: "instructor",
        model: model,
        prompt_version: prompt_version,
        input_snapshot: project_snapshot(project)
      })

    case Client.create_structured_output(
           PromptBuilder.full_brief_messages(project),
           BriefSchema,
           model: model
         ) do
      {:ok, %{parsed: parsed, raw_response: raw_response, model: response_model}} ->
        attrs = to_persistable_map(parsed)

        case create_generated_brief(project, attrs, raw_response, response_model) do
          {:ok, brief} ->
            finish_generation_run(run, %{status: "completed", raw_response: raw_response})
            Workspace.update_project_status(project, "generated")
            {:ok, brief}

          {:error, reason} ->
            message = inspect(reason)
            finish_generation_run(run, %{status: "failed", error: message, raw_response: raw_response})
            {:error, message}
        end

      {:error, reason} ->
        finish_generation_run(run, %{status: "failed", error: to_string(reason)})
        {:error, reason}
    end
  end

  def regenerate_section(%Project{} = project, section) when is_binary(section) do
    with %GeneratedBrief{} = latest_brief <- Workspace.latest_brief(project.id),
         {:ok, _schema} <- BriefSchema.section_schema(section) do
      prompt_version = Application.fetch_env!(:sparkdeck, :llm_prompt_version)
      model = Application.fetch_env!(:sparkdeck, :llm_model)

      {:ok, run} =
        create_generation_run(project, %{
          section: section,
          status: "running",
          provider: "instructor",
          model: model,
          prompt_version: prompt_version,
          input_snapshot: %{
            "project" => project_snapshot(project),
            "brief_id" => latest_brief.id,
            "section" => section
          }
        })

      case Client.create_structured_output(
             PromptBuilder.section_messages(project, latest_brief, section),
             BriefSchema,
             model: model
           ) do
        {:ok, %{parsed: parsed, raw_response: raw_response, model: response_model}} ->
          section_attrs = extract_section_attrs(section, parsed)
          merged_attrs = merge_brief_section(latest_brief, section_attrs)

          case create_generated_brief(project, merged_attrs, raw_response, response_model) do
            {:ok, brief} ->
              finish_generation_run(run, %{status: "completed", raw_response: raw_response})
              {:ok, brief}

            {:error, reason} ->
              message = inspect(reason)
              finish_generation_run(run, %{status: "failed", error: message, raw_response: raw_response})
              {:error, message}
          end

        {:error, reason} ->
          finish_generation_run(run, %{status: "failed", error: to_string(reason)})
          {:error, reason}
      end
    else
      nil -> {:error, "Generate the full brief before regenerating sections"}
      {:error, :error} -> {:error, "Unknown section"}
    end
  end

  defp extract_section_attrs(section, parsed) do
    {:ok, schema} = BriefSchema.section_schema(section)
    keys = Map.keys(schema)
    full = to_persistable_map(parsed)
    Map.take(full, keys)
  end

  defp embedded_to_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.into(%{}, fn
      {k, v} when is_list(v) -> {k, Enum.map(v, &maybe_embedded_to_map/1)}
      {k, v} -> {k, v}
    end)
  end

  defp maybe_embedded_to_map(%{__struct__: _} = struct), do: embedded_to_map(struct)
  defp maybe_embedded_to_map(other), do: other

  defp create_generation_run(project, attrs) do
    %GenerationRun{}
    |> GenerationRun.changeset(Map.put(attrs, :project_id, project.id))
    |> Repo.insert()
  end

  defp finish_generation_run(run, attrs) do
    run
    |> Ecto.Changeset.change(attrs)
    |> Repo.update()
  end

  defp create_generated_brief(project, attrs, raw_response, model) do
    prompt_version = Application.fetch_env!(:sparkdeck, :llm_prompt_version)

    attrs =
      attrs
      |> Map.put(:project_id, project.id)
      |> Map.put(:raw_response, raw_response)
      |> Map.put(:model, model)
      |> Map.put(:prompt_version, prompt_version)

    %GeneratedBrief{}
    |> GeneratedBrief.changeset(attrs)
    |> Repo.insert()
  end

  defp merge_brief_section(brief, section_attrs) do
    base =
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
        :next_steps
      ])

    Map.merge(base, section_attrs)
  end

  defp project_snapshot(project) do
    %{
      "id" => project.id,
      "name" => project.name,
      "idea" => project.idea,
      "target_customer" => project.target_customer,
      "problem" => project.problem,
      "constraints" => project.constraints,
      "product_already_exists" => project.product_already_exists
    }
  end
end
