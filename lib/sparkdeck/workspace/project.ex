defmodule Sparkdeck.Workspace.Project do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sparkdeck.Workspace.{GeneratedBrief, GenerationRun}

  schema "projects" do
    field :name, :string
    field :idea, :string
    field :target_customer, :string
    field :problem, :string
    field :constraints, :string
    field :product_already_exists, :boolean, default: false
    field :status, :string, default: "draft"

    has_many :generated_briefs, GeneratedBrief
    has_many :generation_runs, GenerationRun

    timestamps(type: :utc_datetime)
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :name,
      :idea,
      :target_customer,
      :problem,
      :constraints,
      :product_already_exists,
      :status
    ])
    |> validate_required([:idea, :target_customer, :problem])
    |> validate_length(:name, max: 160)
    |> validate_length(:idea, min: 10, max: 5_000)
    |> validate_length(:target_customer, min: 3, max: 500)
    |> validate_length(:problem, min: 10, max: 2_000)
    |> validate_length(:constraints, max: 2_000)
    |> put_default_name()
  end

  defp put_default_name(changeset) do
    case get_field(changeset, :name) do
      name when is_binary(name) ->
        if String.trim(name) == "" do
          maybe_derive_name(changeset)
        else
          changeset
        end

      _ ->
        maybe_derive_name(changeset)
    end
  end

  defp maybe_derive_name(changeset) do
    idea =
      changeset
      |> get_field(:idea)
      |> normalize_string()

    if idea == "" do
      changeset
    else
      put_change(changeset, :name, derive_name(idea))
    end
  end

  defp derive_name(idea) do
    idea
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(5)
    |> Enum.join(" ")
    |> String.slice(0, 80)
  end

  defp normalize_string(nil), do: ""
  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value |> to_string() |> String.trim()
end
