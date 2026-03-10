defmodule Sparkdeck.Workspace.GeneratedBrief do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sparkdeck.Workspace.Project

  schema "generated_briefs" do
    field :summary, :string
    field :icp_analysis, :string
    field :icp_recommendations, {:array, :string}, default: []
    field :overlooked_segments, {:array, :string}, default: []
    field :pain_points, {:array, :string}, default: []
    field :value_proposition, :string
    field :mvp_features, {:array, :string}, default: []
    field :alternate_approaches, {:array, :string}, default: []
    field :landing_page_content, :map, default: %{}
    field :creative_direction, :map, default: %{}
    field :interview_questions, {:array, :string}, default: []
    field :interview_signals, :map, default: %{}
    field :validation_checklist, :map, default: %{}
    field :go_to_market, :map, default: %{}
    field :fundraising_plan, :map, default: %{}
    field :risks, {:array, :string}, default: []
    field :next_steps, {:array, :string}, default: []
    field :raw_response, :map, default: %{}
    field :model, :string
    field :prompt_version, :string

    belongs_to :project, Project

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(generated_brief, attrs) do
    generated_brief
    |> cast(attrs, [
      :project_id,
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
    |> validate_required([
      :project_id,
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
      :model,
      :prompt_version
    ])
    |> foreign_key_constraint(:project_id)
  end
end
