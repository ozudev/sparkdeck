defmodule Sparkdeck.Workspace.GenerationRun do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sparkdeck.Workspace.Project

  schema "generation_runs" do
    field :section, :string
    field :status, :string
    field :provider, :string
    field :model, :string
    field :prompt_version, :string
    field :input_snapshot, :map, default: %{}
    field :raw_response, :map, default: %{}
    field :error, :string

    belongs_to :project, Project

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :project_id,
      :section,
      :status,
      :provider,
      :model,
      :prompt_version,
      :input_snapshot,
      :raw_response,
      :error
    ])
    |> validate_required([
      :project_id,
      :section,
      :status,
      :provider,
      :model,
      :prompt_version,
      :input_snapshot
    ])
    |> foreign_key_constraint(:project_id)
  end
end
