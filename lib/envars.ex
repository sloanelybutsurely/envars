defmodule Envars do
  @moduledoc """
  `Envars` provides a convenience function to fetch and parse environment
  variables all in once place. This has the benefit of also providing an error
  message listing all missing required values.

  ## Example

      %{
        "PORT" => port,
        "ENABLE_SSL" => enable_ssl,
        "AWS_ACCESS_KEY_ID" => access_key_id,
        "PHX_HOST" => phx_host
      } = Envars.read!(%{
        "PORT" => [type: :integer, required: false, default: 4000],
        "ENABLE_SSL" => [type: :boolean],
        "AWS_ACCESS_KEY_ID" => [type: :string],
        "PHX_HOST" => [type: :string]
      })
  """

  @type field_type :: :string | :integer | :boolean
  @type options :: [
          {:type, field_type()} | {:required, boolean()} | {:default, term()}
        ]

  @spec read!(fields :: %{(field :: String.t()) => options()}) :: %{String.t() => term()}
  def read!(fields) do
    {valid, invalid} =
      for {field, opts} <- fields do
        type = Keyword.get(opts, :type, :string)
        required = Keyword.get(opts, :required, true)
        default = Keyword.get(opts, :default)

        value = System.get_env(field)

        case {value, required, default} do
          {nil, true, nil} -> {:error, {field, :undefined}}
          {nil, _, default} -> {:ok, {field, default}}
          {value, _, _} -> {:ok, {field, parse(type, value)}}
        end
      end
      |> Enum.split_with(&(elem(&1, 0) == :ok))

    if Enum.empty?(invalid) do
      for {:ok, {field, value}} <- valid, into: %{}, do: {field, value}
    else
      missing_fields = for {:error, {field, _}} <- invalid, do: field
      raise "Missing environment variables:\n\n - #{Enum.join(missing_fields, "\n - ")}"
    end
  end

  defp parse(:string, value), do: value
  defp parse(:integer, value), do: String.to_integer(value)
  defp parse(:boolean, "0"), do: false
  defp parse(:boolean, "1"), do: true
  defp parse(:boolean, value), do: String.downcase(value) == "true"
end
