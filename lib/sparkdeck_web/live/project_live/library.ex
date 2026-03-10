defmodule SparkdeckWeb.ProjectLive.Library do
  use SparkdeckWeb, :live_view

  alias Sparkdeck.Workspace

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Projects")
     |> assign(projects: Workspace.list_projects())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="spark-page">
      <div class="spark-page__inner spark-list-page">
        <header class="spark-topbar">
          <div>
            <p class="spark-kicker">Library</p>
            <h1 class="spark-headline" style="font-size: clamp(2.4rem, 6vw, 4rem); max-width: 560px;">
              Saved projects and generated briefs.
            </h1>
          </div>
          <nav class="spark-nav">
            <.link navigate={~p"/"} class="spark-link">New brief</.link>
            <Layouts.theme_toggle />
          </nav>
        </header>

        <section class="project-list">
          <%= if @projects == [] do %>
            <div class="spark-panel">
              <div class="spark-panel__body">
                <h2 class="spark-panel__title">No projects yet</h2>
                <p class="spark-panel__meta">Create the first brief from the home page.</p>
              </div>
            </div>
          <% else %>
            <.link
              :for={project <- @projects}
              navigate={~p"/projects/#{project.id}"}
              class="project-item"
            >
              <div class="project-item__meta">
                <span>{project.status}</span>
                <span>{format_datetime(project.updated_at)}</span>
              </div>
              <h2 class="spark-panel__title">{project.name}</h2>
              <p class="spark-panel__meta">{project.idea}</p>
            </.link>
          <% end %>
        </section>
      </div>
    </div>
    """
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y")
  end
end
