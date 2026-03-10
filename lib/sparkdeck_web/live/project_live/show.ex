defmodule SparkdeckWeb.ProjectLive.Show do
  use SparkdeckWeb, :live_view

  alias Sparkdeck.Workspace

  @regenerable_sections [
    {"summary", "Summary"},
    {"icp_analysis", "ICP"},
    {"value_proposition", "Offer"},
    {"landing_page_content", "Landing Page"},
    {"creative_direction", "Creative"},
    {"interview_questions", "Validation"},
    {"go_to_market", "GTM"},
    {"fundraising_plan", "Fundraising"},
    {"risks", "Risks"}
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {project, brief} = Workspace.get_project_with_latest_brief!(id)

    {:ok,
     socket
     |> assign(page_title: project.name)
     |> assign(project: project, brief: brief, generating?: false)
     |> assign(regenerable_sections: @regenerable_sections)
     |> assign(show_inputs: false)
     |> assign_project_form(project)}
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
          <header class="brief-header">
            <h1 class="brief-title">{@project.name}</h1>
            <div class="brief-actions">
              <button
                :if={@brief}
                type="button"
                phx-click="toggle_inputs"
                class="brief-action-link"
              >
                {if @show_inputs, do: "Hide inputs", else: "Edit inputs"}
              </button>
              <button
                type="button"
                phx-click="duplicate"
                class="brief-action-link"
              >
                Duplicate
              </button>
              <.button
                phx-click="generate"
                variant="submit"
                disabled={@generating?}
                phx-disable-with={if @brief, do: "Regenerating...", else: "Generating..."}
              >
                {if @brief, do: "Regenerate all", else: "Generate brief"}
              </.button>
            </div>
          </header>

          <div :if={@show_inputs} class="brief-inputs">
            <.form
              for={@project_form}
              id="project-edit-form"
              phx-change="validate_project"
              phx-submit="save_project"
            >
              <.input field={@project_form[:name]} label="Project name" />
              <.input field={@project_form[:idea]} type="textarea" label="Idea" rows="3" />
              <.input field={@project_form[:target_customer]} label="Who is this for?" />
              <.input field={@project_form[:problem]} type="textarea" label="Problem" rows="3" />
              <.input
                field={@project_form[:product_already_exists]}
                type="checkbox"
                label="Products already exist in this market"
              />
              <.button variant="submit" phx-disable-with="Saving...">Save inputs</.button>
            </.form>
          </div>

          <%= if @brief do %>
            <div class="brief-section-nav">
              <button
                :for={{section, label} <- @regenerable_sections}
                type="button"
                phx-click="regenerate_section"
                phx-value-section={section}
                class="brief-section-chip"
                disabled={@generating?}
              >
                {label}
              </button>
            </div>

            <div class="brief-content">
              <.text_section title="Summary" body={@brief.summary} />
              <.text_section title="ICP Analysis" body={@brief.icp_analysis} />
              <.list_section title="ICP Recommendations" items={@brief.icp_recommendations} />
              <.list_section title="Overlooked Segments" items={@brief.overlooked_segments} />
              <.list_section title="Pain Points" items={@brief.pain_points} />
              <.text_section title="Value Proposition" body={@brief.value_proposition} />
              <.list_section title="MVP Features" items={@brief.mvp_features} />
              <.list_section
                :if={Enum.any?(@brief.alternate_approaches)}
                title="Alternate Approaches"
                items={@brief.alternate_approaches}
              />
              <.landing_page_section content={@brief.landing_page_content} />
              <.keyed_section title="Creative Direction" data={@brief.creative_direction} />
              <.list_section title="Interview Questions" items={@brief.interview_questions} />
              <.keyed_section title="Interview Signals" data={@brief.interview_signals} />
              <.keyed_section title="Validation Checklist" data={@brief.validation_checklist} />
              <.keyed_section title="Go to Market" data={@brief.go_to_market} />
              <.keyed_section title="Fundraising Plan" data={@brief.fundraising_plan} />
              <.list_section title="Risks" items={@brief.risks} />
              <.list_section title="Next Steps" items={@brief.next_steps} />
            </div>
          <% else %>
            <div class="brief-empty">
              <p>No brief generated yet. Hit generate to get started.</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate_project", %{"project" => params}, socket) do
    changeset =
      socket.assigns.project
      |> Workspace.change_project(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :project_form, to_form(changeset))}
  end

  def handle_event("save_project", %{"project" => params}, socket) do
    case Workspace.update_project(socket.assigns.project, params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> assign(project: project, show_inputs: false)
         |> assign_project_form(project)
         |> put_flash(:info, "Project updated")}

      {:error, changeset} ->
        {:noreply, assign(socket, :project_form, to_form(changeset))}
    end
  end

  def handle_event("toggle_inputs", _params, socket) do
    {:noreply, assign(socket, :show_inputs, !socket.assigns.show_inputs)}
  end

  def handle_event("generate", _params, socket) do
    socket = assign(socket, :generating?, true)

    case Workspace.generate_brief(socket.assigns.project) do
      {:ok, brief} ->
        {:noreply,
         socket
         |> assign(brief: brief, generating?: false)
         |> put_flash(:info, "Brief generated")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:generating?, false)
         |> put_flash(:error, humanize_error(reason))}
    end
  end

  def handle_event("regenerate_section", %{"section" => section}, socket) do
    socket = assign(socket, :generating?, true)

    case Workspace.regenerate_section(socket.assigns.project, section) do
      {:ok, brief} ->
        {:noreply,
         socket
         |> assign(brief: brief, generating?: false)
         |> put_flash(:info, "#{label_for(section)} regenerated")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:generating?, false)
         |> put_flash(:error, humanize_error(reason))}
    end
  end

  def handle_event("duplicate", _params, socket) do
    case Workspace.duplicate_project(socket.assigns.project) do
      {:ok, project} ->
        {:noreply, push_navigate(socket, to: ~p"/projects/#{project.id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, humanize_error(reason))}
    end
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
      <div :for={{key, value} <- @data} class="brief-subsection">
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
    assigns =
      assigns
      |> assign(:headline, map_value(assigns.content, "headline"))
      |> assign(:subheadline, map_value(assigns.content, "subheadline"))
      |> assign(:benefits, map_value(assigns.content, "benefits") || [])
      |> assign(:cta, map_value(assigns.content, "cta"))
      |> assign(:faq, map_value(assigns.content, "faq") || [])

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

  defp assign_project_form(socket, project) do
    assign(socket, :project_form, to_form(Workspace.change_project(project)))
  end

  defp label_for(section) do
    Enum.find_value(@regenerable_sections, section, fn
      {^section, label} -> label
      _ -> nil
    end)
  end

  defp humanize_error(%Ecto.Changeset{}), do: "Generated output failed validation"
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
