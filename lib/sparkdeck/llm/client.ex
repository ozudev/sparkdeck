defmodule Sparkdeck.LLM.Client do
  require Logger

  def create_structured_output(messages, response_model, opts \\ []) do
    model = Keyword.get(opts, :model, Application.fetch_env!(:sparkdeck, :llm_model))
    max_retries = Keyword.get(opts, :max_retries, 3)

    instructor_opts = [
      model: model,
      response_model: response_model,
      max_retries: max_retries,
      mode: :json,
      messages: messages
    ]

    case Instructor.chat_completion(instructor_opts, adapter_config()) do
      {:ok, result} ->
        {:ok,
         %{
           parsed: result,
           model: model,
           raw_response: %{
             "model" => model,
             "parsed" => to_map(result)
           }
         }}

      {:error, reason} ->
        Logger.error("Instructor structured output failed: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Instructor call raised: #{Exception.message(error)}")
      {:error, Exception.message(error)}
  end

  defp adapter_config do
    config = Application.get_env(:instructor, :openai, [])
    Keyword.put(config, :adapter, Sparkdeck.LLM.Adapter)
  end

  defp to_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Enum.into(%{}, fn {k, v} -> {k, to_map(v)} end)
  end

  defp to_map(list) when is_list(list), do: Enum.map(list, &to_map/1)
  defp to_map(value), do: value
end
