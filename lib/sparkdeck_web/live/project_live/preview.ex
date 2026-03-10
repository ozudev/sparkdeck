defmodule SparkdeckWeb.ProjectLive.Preview do
  use SparkdeckWeb, :live_view

  alias Sparkdeck.Workspace

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Preview")
     |> assign(project_params: nil, brief_attrs: nil, raw_response: nil, model: nil)
     |> assign(state: :loading, error: nil)}
  end

  @impl true
  def handle_params(%{"project" => project_params}, _uri, socket) do
    name = derive_name(project_params["idea"])

    socket =
      socket
      |> assign(project_params: project_params, project_name: name, page_title: name)

    socket =
      if connected?(socket) do
        start_async(socket, :generate, fn ->
          Workspace.generate_preview(project_params)
        end)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
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
            <.link navigate={~p"/"} class="spark-link">New</.link>
            <.link navigate={~p"/projects"} class="spark-link">Projects</.link>
            <Layouts.theme_toggle />
          </nav>
        </header>

        <div class="brief-layout">
          <%= case @state do %>
            <% :loading -> %>
              <div class="loading-inner">
                <div class="loading-indicator"></div>
                <p class="loading-kicker">Generating</p>
                <h1 class="loading-title">{@project_name}</h1>
                <p class="loading-copy">
                  Building validation brief, ICP critique, messaging, and early validation plan.
                </p>
              </div>

            <% :error -> %>
              <div class="loading-inner">
                <h1 class="loading-title">{@project_name}</h1>
                <div class="loading-error">
                  <p class="loading-error__label">Generation failed</p>
                  <p class="loading-error__body">{@error}</p>
                  <div class="loading-error__actions">
                    <.button phx-click="retry" variant="submit">Try again</.button>
                    <.button navigate={~p"/"} variant="ghost">Start over</.button>
                  </div>
                </div>
              </div>

            <% :ready -> %>
              <header class="brief-header">
                <h1 class="brief-title">{@project_name}</h1>
                <div class="brief-actions">
                  <.button navigate={~p"/"} variant="ghost">Discard</.button>
                  <.button phx-click="save" variant="submit" phx-disable-with="Saving...">
                    Save project
                  </.button>
                </div>
              </header>

              <div class="brief-content">
                <.text_section title="Summary" body={@brief_attrs[:summary]} />
                <.text_section title="ICP Analysis" body={@brief_attrs[:icp_analysis]} />
                <.list_section title="ICP Recommendations" items={@brief_attrs[:icp_recommendations]} />
                <.list_section title="Overlooked Segments" items={@brief_attrs[:overlooked_segments]} />
                <.list_section title="Pain Points" items={@brief_attrs[:pain_points]} />
                <.text_section title="Value Proposition" body={@brief_attrs[:value_proposition]} />
                <.list_section title="MVP Features" items={@brief_attrs[:mvp_features]} />
                <.list_section
                  :if={Enum.any?(@brief_attrs[:alternate_approaches] || [])}
                  title="Alternate Approaches"
                  items={@brief_attrs[:alternate_approaches]}
                />
                <.landing_page_section content={@brief_attrs[:landing_page_content]} />
                <.keyed_section title="Creative Direction" data={@brief_attrs[:creative_direction]} />
                <.list_section title="Interview Questions" items={@brief_attrs[:interview_questions]} />
                <.keyed_section title="Interview Signals" data={@brief_attrs[:interview_signals]} />
                <.keyed_section title="Validation Checklist" data={@brief_attrs[:validation_checklist]} />
                <.keyed_section title="Go to Market" data={@brief_attrs[:go_to_market]} />
                <.keyed_section title="Fundraising Plan" data={@brief_attrs[:fundraising_plan]} />
                <.list_section title="Risks" items={@brief_attrs[:risks]} />
                <.list_section title="Next Steps" items={@brief_attrs[:next_steps]} />
              </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("retry", _params, socket) do
    params = socket.assigns.project_params

    {:noreply,
     socket
     |> assign(state: :loading, error: nil)
     |> start_async(:generate, fn ->
       Workspace.generate_preview(params)
     end)}
  end

  def handle_event("save", _params, socket) do
    %{project_params: params, brief_attrs: brief_attrs, raw_response: raw, model: model} =
      socket.assigns

    case Workspace.save_preview(params, brief_attrs, raw, model) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project saved")
         |> push_navigate(to: ~p"/projects/#{project.id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, humanize_error(reason))}
    end
  end

  @impl true
  def handle_async(:generate, {:ok, {:ok, result}}, socket) do
    {:noreply,
     socket
     |> assign(
       state: :ready,
       brief_attrs: result.brief_attrs,
       raw_response: result.raw_response,
       model: result.model
     )}
  end

  def handle_async(:generate, {:ok, {:error, reason}}, socket) do
    {:noreply, assign(socket, state: :error, error: humanize_error(reason))}
  end

  def handle_async(:generate, {:exit, reason}, socket) do
    {:noreply, assign(socket, state: :error, error: humanize_error(reason))}
  end

  # -- Components --

  attr :title, :string, required: true
  attr :body, :string, required: true

  defp text_section(assigns) do
    ~H"""
    <section class="brief-section">
      <h2 class="brief-section__title">{@title}</h2>
      <p class="brief-section__body">{@body}</p>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :items, :list, default: []

  defp list_section(assigns) do
    ~H"""
    <section class="brief-section">
      <h2 class="brief-section__title">{@title}</h2>
      <ul class="brief-section__list">
        <li :for={item <- @items}>{item}</li>
      </ul>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :data, :map, default: %{}

  defp keyed_section(assigns) do
    ~H"""
    <section class="brief-section">
      <h2 class="brief-section__title">{@title}</h2>
      <div :for={{key, value} <- @data || %{}} class="brief-subsection">
        <h3 class="brief-subsection__title">{humanize_key(key)}</h3>
        <%= if is_list(value) do %>
          <ul class="brief-section__list">
            <li :for={item <- value}>{render_value(item)}</li>
          </ul>
        <% else %>
          <p class="brief-section__body">{render_value(value)}</p>
        <% end %>
      </div>
    </section>
    """
  end

  attr :content, :map, required: true

  defp landing_page_section(assigns) do
    content = assigns.content || %{}

    assigns =
      assigns
      |> assign(:headline, map_value(content, "headline"))
      |> assign(:subheadline, map_value(content, "subheadline"))
      |> assign(:benefits, map_value(content, "benefits") || [])
      |> assign(:cta, map_value(content, "cta"))
      |> assign(:faq, map_value(content, "faq") || [])

    ~H"""
    <section class="brief-section">
      <h2 class="brief-section__title">Landing Page</h2>
      <div class="brief-subsection">
        <h3 class="brief-subsection__title">Headline</h3>
        <p class="brief-section__body">{@headline}</p>
      </div>
      <div class="brief-subsection">
        <h3 class="brief-subsection__title">Subheadline</h3>
        <p class="brief-section__body">{@subheadline}</p>
      </div>
      <div class="brief-subsection">
        <h3 class="brief-subsection__title">Benefits</h3>
        <ul class="brief-section__list">
          <li :for={benefit <- @benefits}>{benefit}</li>
        </ul>
      </div>
      <div class="brief-subsection">
        <h3 class="brief-subsection__title">CTA</h3>
        <p class="brief-section__body">{@cta}</p>
      </div>
      <div :if={@faq != []} class="brief-subsection">
        <h3 class="brief-subsection__title">FAQ</h3>
        <div :for={entry <- @faq} class="brief-faq-entry">
          <p class="brief-faq-q">{map_value(entry, "question")}</p>
          <p class="brief-section__body">{map_value(entry, "answer")}</p>
        </div>
      </div>
    </section>
    """
  end

  # -- Helpers --

  defp derive_name(nil), do: "Untitled"

  defp derive_name(idea) do
    idea
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(5)
    |> Enum.join(" ")
    |> String.slice(0, 80)
  end

  defp humanize_error(%Ecto.Changeset{}), do: "Validation failed"
  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: inspect(reason)

  defp humanize_key(key) when is_atom(key), do: key |> Atom.to_string() |> humanize_key()
  defp humanize_key(key), do: key |> String.replace("_", " ") |> String.capitalize()

  defp render_value(value) when is_map(value), do: Jason.encode!(value)
  defp render_value(value), do: value

  defp map_value(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key)) || ""
  rescue
    ArgumentError -> Map.get(map, key, "")
  end
end
