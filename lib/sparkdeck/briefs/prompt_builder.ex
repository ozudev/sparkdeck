defmodule Sparkdeck.Briefs.PromptBuilder do
  alias Sparkdeck.Workspace.{GeneratedBrief, Project}

  def full_brief_messages(%Project{} = project) do
    [
      %{
        role: "user",
        content: """
        You are Sparkdeck, a critical startup validation assistant.
        Your job is to convert rough startup ideas into a structured validation brief.
        Do not flatter the user. Challenge weak ICPs, weak assumptions, and vague positioning.
        Keep outputs concise, specific, and actionable.

        Generate a structured validation brief for this startup idea.

        Project name: #{project.name}
        Idea: #{project.idea}
        Target customer: #{project.target_customer}
        Problem: #{project.problem}
        Constraints: #{blank_or_value(project.constraints)}
        Product already exists in market: #{yes_no(project.product_already_exists)}

        Requirements:
        - Assess whether the target customer is viable.
        - Explain whether the ICP is too broad, too narrow, weak, or misaligned.
        - Recommend a better ICP if needed.
        - Identify overlooked adjacent segments.
        - Include alternate approaches even if the market already has existing products.
        - Keep fundraising and GTM guidance short and concrete.
        - Use Mom Test-style interview questions.
        """
      }
    ]
  end

  def section_messages(%Project{} = project, %GeneratedBrief{} = brief, section) do
    [
      %{
        role: "user",
        content: """
        You are Sparkdeck, a critical startup validation assistant.
        Regenerate only the requested section while keeping the full response structure.
        Keep the output consistent with the existing project context while improving specificity.

        Regenerate the `#{section}` section for this project.

        Project name: #{project.name}
        Idea: #{project.idea}
        Target customer: #{project.target_customer}
        Problem: #{project.problem}
        Constraints: #{blank_or_value(project.constraints)}
        Product already exists in market: #{yes_no(project.product_already_exists)}

        Existing brief context:
        #{brief_context(brief)}
        """
      }
    ]
  end

  defp brief_context(brief) do
    Jason.encode!(%{
      summary: brief.summary,
      icp_analysis: brief.icp_analysis,
      icp_recommendations: brief.icp_recommendations,
      overlooked_segments: brief.overlooked_segments,
      pain_points: brief.pain_points,
      value_proposition: brief.value_proposition,
      mvp_features: brief.mvp_features,
      alternate_approaches: brief.alternate_approaches,
      landing_page_content: brief.landing_page_content,
      creative_direction: brief.creative_direction,
      interview_questions: brief.interview_questions,
      interview_signals: brief.interview_signals,
      validation_checklist: brief.validation_checklist,
      go_to_market: brief.go_to_market,
      fundraising_plan: brief.fundraising_plan,
      risks: brief.risks,
      next_steps: brief.next_steps
    })
  end

  defp blank_or_value(nil), do: "None"
  defp blank_or_value(""), do: "None"
  defp blank_or_value(value), do: value

  defp yes_no(true), do: "Yes"
  defp yes_no("true"), do: "Yes"
  defp yes_no(_), do: "No"
end
