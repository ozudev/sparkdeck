defmodule SparkdeckWeb.ProjectLive.Index do
  use SparkdeckWeb, :live_view

  alias Sparkdeck.Workspace
  alias Sparkdeck.Workspace.Project

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Sparkdeck")
     |> assign_new_project_form(Workspace.change_project(%Project{}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="spark-page">
      <div class="spark-page__inner">
        <header class="spark-topbar">
          <.link navigate={~p"/"} class="spark-brand">
            <span class="spark-brand__mark"></span> Sparkdeck
          </.link>
          <nav class="spark-nav">
            <.link navigate={~p"/projects"} class="spark-link">Projects</.link>
            <Layouts.theme_toggle />
          </nav>
        </header>

        <section class="spark-hero">
          <div>
            <p class="spark-kicker">Idea to validation</p>
            <h1 class="spark-headline">
              Pressure-test the idea before you write a line of product code.
            </h1>
          </div>
        </section>

        <div class="spark-form-container">
          <.form for={@form} id="project-form" phx-change="validate" phx-submit="generate">
            <.input
              field={@form[:idea]}
              label="What are you building?"
              placeholder="AI copilot for independent insurance agencies"
              required
            />

            <.input
              field={@form[:target_customer]}
              label="Who is this for?"
              placeholder="Independent insurance brokers"
              required
            />

            <.input
              field={@form[:problem]}
              type="textarea"
              label="What problem are you solving?"
              placeholder="Quoting and follow-up are slow, manual, and fragmented"
              rows="2"
              required
            />

            <.input
              field={@form[:product_already_exists]}
              type="checkbox"
              label="Products already exist in this market"
            />

            <.button variant="submit" phx-disable-with="Preparing brief...">
              Generate brief
            </.button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Workspace.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_new_project_form(socket, changeset)}
  end

  def handle_event("generate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Workspace.change_project(project_params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      {:noreply,
       socket
       |> push_navigate(to: ~p"/preview?#{%{project: project_params}}")}
    else
      {:noreply, assign_new_project_form(socket, changeset)}
    end
  end

  defp assign_new_project_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
