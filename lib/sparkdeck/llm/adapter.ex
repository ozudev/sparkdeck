defmodule Sparkdeck.LLM.Adapter do
  @moduledoc """
  Custom Instructor adapter that handles models which wrap JSON in markdown fences
  and ignore response_format parameters.
  """
  @behaviour Instructor.Adapter

  @receive_timeout 120_000

  @impl true
  def chat_completion(params, config \\ nil) do
    params =
      params
      |> Keyword.delete(:response_format)
      |> Keyword.delete(:stop)

    config = build_config(config)

    url = Keyword.fetch!(config, :api_url) <> Keyword.fetch!(config, :api_path)
    api_key = Keyword.get(config, :api_key)
    timeout = Keyword.get(config, :receive_timeout, @receive_timeout)

    {_, params} = Keyword.pop(params, :response_model)
    {_, params} = Keyword.pop(params, :validation_context)
    {_, params} = Keyword.pop(params, :max_retries)
    {_, params} = Keyword.pop(params, :mode)
    body = Enum.into(params, %{})

    headers = [{"content-type", "application/json"}]

    headers =
      if api_key do
        [{"authorization", "Bearer #{api_key}"} | headers]
      else
        headers
      end

    case Req.post(url, json: body, headers: headers, receive_timeout: timeout) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        with content when is_binary(content) <-
               get_in(body, ["choices", Access.at(0), "message", "content"]),
             cleaned <- strip_markdown_fences(content),
             {:ok, parsed} <- Jason.decode(cleaned) do
          {:ok, body, parsed}
        else
          nil ->
            {:error, "No content in LLM response"}

          {:error, %Jason.DecodeError{position: pos, data: data}} ->
            snippet = String.slice(data, max(pos - 40, 0), 80)
            {:error, "Invalid JSON at position #{pos}: ...#{snippet}..."}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, "LLM request timed out after #{div(timeout, 1000)}s"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  @impl true
  def reask_messages(raw_response, _params, _config) do
    content =
      get_in(raw_response, ["choices", Access.at(0), "message", "content"]) || ""

    [%{role: "assistant", content: content}]
  end

  defp strip_markdown_fences(text) do
    text
    |> String.trim()
    |> remove_opening_fence()
    |> remove_closing_fence()
    |> String.trim()
  end

  defp remove_opening_fence(text) do
    Regex.replace(~r/\A```(?:json)?\s*\n?/, text, "", global: false)
  end

  defp remove_closing_fence(text) do
    Regex.replace(~r/\n?```\s*\z/, text, "")
  end

  defp build_config(nil), do: build_config(Application.get_env(:instructor, :openai, []))

  defp build_config(config) do
    defaults = [
      api_url: "https://api.openai.com",
      api_path: "/v1/chat/completions",
      receive_timeout: @receive_timeout
    ]

    Keyword.merge(defaults, config)
  end
end
