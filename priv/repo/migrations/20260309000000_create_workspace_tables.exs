defmodule Sparkdeck.Repo.Migrations.CreateWorkspaceTables do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :idea, :text, null: false
      add :target_customer, :text, null: false
      add :problem, :text, null: false
      add :constraints, :text
      add :product_already_exists, :boolean, null: false, default: false
      add :status, :string, null: false, default: "draft"

      timestamps(type: :utc_datetime)
    end

    create table(:generated_briefs) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :summary, :text, null: false
      add :icp_analysis, :text, null: false
      add :icp_recommendations, {:array, :text}, null: false, default: []
      add :overlooked_segments, {:array, :text}, null: false, default: []
      add :pain_points, {:array, :text}, null: false, default: []
      add :value_proposition, :text, null: false
      add :mvp_features, {:array, :text}, null: false, default: []
      add :alternate_approaches, {:array, :text}, null: false, default: []
      add :landing_page_content, :map, null: false
      add :creative_direction, :map, null: false
      add :interview_questions, {:array, :text}, null: false, default: []
      add :interview_signals, :map, null: false
      add :validation_checklist, :map, null: false
      add :go_to_market, :map, null: false
      add :fundraising_plan, :map, null: false
      add :risks, {:array, :text}, null: false, default: []
      add :next_steps, {:array, :text}, null: false, default: []
      add :raw_response, :map
      add :model, :string, null: false
      add :prompt_version, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create table(:generation_runs) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :section, :string, null: false
      add :status, :string, null: false
      add :provider, :string, null: false
      add :model, :string, null: false
      add :prompt_version, :string, null: false
      add :input_snapshot, :map, null: false
      add :raw_response, :map
      add :error, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:generated_briefs, [:project_id, :inserted_at])
    create index(:generation_runs, [:project_id, :inserted_at])
  end
end
