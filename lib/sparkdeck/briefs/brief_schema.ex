defmodule Sparkdeck.Briefs.BriefSchema do
  use Ecto.Schema
  use Instructor
  import Ecto.Changeset

  @llm_doc """
  A structured startup validation brief with all required sections.

  ## Field Descriptions:
  - summary: A concise summary of the startup idea validation assessment.
  - icp_analysis: Analysis of the Ideal Customer Profile viability.
  - icp_recommendations: List of recommended improvements to the ICP.
  - overlooked_segments: Adjacent customer segments that may have been missed.
  - pain_points: Key pain points identified for the target customer.
  - value_proposition: The core value proposition statement.
  - mvp_features: Minimum viable product feature list.
  - alternate_approaches: Alternative approaches to solving the problem.
  - landing_page_content: Landing page copy including headline, subheadline, benefits, CTA, and FAQ.
  - creative_direction: Visual and messaging direction for marketing.
  - interview_questions: Mom Test-style customer interview questions.
  - interview_signals: Signals to listen for during customer interviews.
  - validation_checklist: Checklist for validating the idea before building.
  - go_to_market: Go-to-market strategy with hypothesis, channels, and first campaign.
  - fundraising_plan: Fundraising narrative with story, milestones, and use of funds.
  - risks: Key risks to the startup idea.
  - next_steps: Concrete next steps for validation.
  """

  @primary_key false
  embedded_schema do
    field :summary, :string
    field :icp_analysis, :string
    field :icp_recommendations, {:array, :string}, default: []
    field :overlooked_segments, {:array, :string}, default: []
    field :pain_points, {:array, :string}, default: []
    field :value_proposition, :string
    field :mvp_features, {:array, :string}, default: []
    field :alternate_approaches, {:array, :string}, default: []
    embeds_one :landing_page_content, LandingPageContent, primary_key: false do
      field :headline, :string
      field :subheadline, :string
      field :benefits, {:array, :string}, default: []
      field :cta, :string
      embeds_many :faq, FAQ, primary_key: false do
        field :question, :string
        field :answer, :string
      end
    end
    embeds_one :creative_direction, CreativeDirection, primary_key: false do
      field :visual_direction_ideas, {:array, :string}, default: []
      field :messaging_angles, {:array, :string}, default: []
      field :campaign_themes, {:array, :string}, default: []
    end
    field :interview_questions, {:array, :string}, default: []
    embeds_one :interview_signals, InterviewSignals, primary_key: false do
      field :what_to_listen_for, {:array, :string}, default: []
      field :real_pain_signals, {:array, :string}, default: []
      field :polite_interest_signals, {:array, :string}, default: []
    end
    embeds_one :validation_checklist, ValidationChecklist, primary_key: false do
      field :who_to_interview, {:array, :string}, default: []
      field :tests_before_building, {:array, :string}, default: []
      field :success_signals, {:array, :string}, default: []
      field :failure_signals, {:array, :string}, default: []
    end
    embeds_one :go_to_market, GoToMarket, primary_key: false do
      field :hypothesis, :string
      field :early_channels, {:array, :string}, default: []
      field :first_campaign, :string
    end
    embeds_one :fundraising_plan, FundraisingPlan, primary_key: false do
      field :story, :string
      field :milestones, {:array, :string}, default: []
      field :use_of_funds, {:array, :string}, default: []
    end
    field :risks, {:array, :string}, default: []
    field :next_steps, {:array, :string}, default: []
  end

  @fields [
    :summary,
    :icp_analysis,
    :icp_recommendations,
    :overlooked_segments,
    :pain_points,
    :value_proposition,
    :mvp_features,
    :alternate_approaches,
    :interview_questions,
    :risks,
    :next_steps
  ]

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required(@fields)
  end

  def validate_full(attrs) do
    if is_map(attrs) do
      %__MODULE__{}
      |> changeset(attrs)
      |> apply_action(:validate)
    else
      {:error, "Model did not return structured JSON"}
    end
  end

  def validate_section(section, attrs) do
    with {:ok, schema} <- section_schema(section) do
      if is_map(attrs) do
        required = Map.keys(schema)

        attrs =
          attrs
          |> stringify_keys()
          |> Map.take(Enum.map(required, &Atom.to_string/1))

        changes =
          Enum.reduce(required, %{}, fn key, acc ->
            value = Map.get(attrs, Atom.to_string(key))
            Map.put(acc, key, value)
          end)

        {:ok, changes}
      else
        {:error, "Model did not return structured JSON for section #{section}"}
      end
    end
  end

  def section_schema(section) do
    Map.fetch(section_schemas(), section)
  end

  defp changeset(struct, attrs) do
    struct
    |> Ecto.Changeset.cast(attrs, @fields)
    |> Ecto.Changeset.cast_embed(:landing_page_content, with: &landing_page_changeset/2)
    |> Ecto.Changeset.cast_embed(:creative_direction, with: &creative_direction_changeset/2)
    |> Ecto.Changeset.cast_embed(:interview_signals, with: &interview_signals_changeset/2)
    |> Ecto.Changeset.cast_embed(:validation_checklist, with: &validation_checklist_changeset/2)
    |> Ecto.Changeset.cast_embed(:go_to_market, with: &go_to_market_changeset/2)
    |> Ecto.Changeset.cast_embed(:fundraising_plan, with: &fundraising_plan_changeset/2)
    |> Ecto.Changeset.validate_required(@fields)
  end

  defp landing_page_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:headline, :subheadline, :benefits, :cta])
    |> Ecto.Changeset.cast_embed(:faq, with: &faq_changeset/2)
    |> Ecto.Changeset.validate_required([:headline, :subheadline, :benefits, :cta])
  end

  defp faq_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:question, :answer])
    |> Ecto.Changeset.validate_required([:question, :answer])
  end

  defp creative_direction_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:visual_direction_ideas, :messaging_angles, :campaign_themes])
    |> Ecto.Changeset.validate_required([:visual_direction_ideas, :messaging_angles, :campaign_themes])
  end

  defp interview_signals_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:what_to_listen_for, :real_pain_signals, :polite_interest_signals])
    |> Ecto.Changeset.validate_required([:what_to_listen_for, :real_pain_signals, :polite_interest_signals])
  end

  defp validation_checklist_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:who_to_interview, :tests_before_building, :success_signals, :failure_signals])
    |> Ecto.Changeset.validate_required([:who_to_interview, :tests_before_building, :success_signals, :failure_signals])
  end

  defp go_to_market_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:hypothesis, :early_channels, :first_campaign])
    |> Ecto.Changeset.validate_required([:hypothesis, :early_channels, :first_campaign])
  end

  defp fundraising_plan_changeset(schema, attrs) do
    schema
    |> Ecto.Changeset.cast(attrs, [:story, :milestones, :use_of_funds])
    |> Ecto.Changeset.validate_required([:story, :milestones, :use_of_funds])
  end

  defp section_schemas do
    %{
      "summary" => %{summary: :string},
      "icp_analysis" => %{
        icp_analysis: :string,
        icp_recommendations: {:array, :string},
        overlooked_segments: {:array, :string}
      },
      "value_proposition" => %{
        pain_points: {:array, :string},
        value_proposition: :string,
        mvp_features: {:array, :string},
        alternate_approaches: {:array, :string}
      },
      "landing_page_content" => %{landing_page_content: :map},
      "creative_direction" => %{creative_direction: :map},
      "interview_questions" => %{
        interview_questions: {:array, :string},
        interview_signals: :map,
        validation_checklist: :map
      },
      "go_to_market" => %{go_to_market: :map},
      "fundraising_plan" => %{fundraising_plan: :map},
      "risks" => %{risks: {:array, :string}, next_steps: {:array, :string}}
    }
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      pair -> pair
    end)
  end
end
