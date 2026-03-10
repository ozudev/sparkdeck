defmodule SparkdeckWeb.ProjectLive.Loading do
  use SparkdeckWeb, :live_view

  alias Sparkdeck.Workspace

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {project, brief} = Workspace.get_project_with_latest_brief!(id)

    if brief do
      {:ok, push_navigate(socket, to: ~p"/projects/#{project.id}")}
    else
      socket =
        socket
        |> assign(page_title: "Generating brief")
        |> assign(project: project, brief: brief, error: nil)

      socket =
        if connected?(socket) do
          start_async(socket, :generate_brief, fn -> Workspace.generate_brief(project) end)
        else
          socket
        end

      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div class="loading-shell">
      <div class="loading-inner">
        <div class="loading-indicator"></div>
        <p class="loading-kicker">Generating</p>
        <h1 class="loading-title">{@project.name}</h1>
        <p class="loading-copy">
          Building validation brief, ICP critique, messaging, and early validation plan.
        </p>

        <div :if={@error} class="loading-error">
          <p class="loading-error__label">Generation failed</p>
          <p class="loading-error__body">{@error}</p>
          <div class="loading-error__actions">
            <.button phx-click="retry" variant="submit">Try again</.button>
            <.button navigate={~p"/"} variant="ghost">Back</.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("retry", _params, socket) do
    project = socket.assigns.project

    {:noreply,
     socket
     |> assign(:error, nil)
     |> start_async(:generate_brief, fn -> Workspace.generate_brief(project) end)}
  end

  @impl true
  def handle_async(:generate_brief, {:ok, {:ok, _brief}}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/projects/#{socket.assigns.project.id}")}
  end

  def handle_async(:generate_brief, {:ok, {:error, reason}}, socket) do
    {:noreply, assign(socket, :error, humanize_error(reason))}
  end

  def handle_async(:generate_brief, {:exit, reason}, socket) do
    {:noreply, assign(socket, :error, humanize_error(reason))}
  end

  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: inspect(reason)
end
