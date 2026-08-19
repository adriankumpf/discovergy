defmodule Discovergy.Application do
  @moduledoc false

  use Application

  alias Discovergy.Config

  @impl true
  def start(_type, _opts) do
    client = Config.client()
    ensure_started!(client)

    client.child_spec(Config.client_pool_opts())
    |> List.wrap()
    |> Supervisor.start_link(strategy: :one_for_one, name: Discovergy.Supervisor)
  end

  # :finch is an optional dependency, so it is neither loaded nor started for
  # us if the application that depends on Discovergy did not ask for it.
  defp ensure_started!(Discovergy.HTTPClient.Finch) do
    Code.ensure_loaded?(Finch) ||
      raise """
      Discovergy failed to start. Add :finch to your dependencies to fix this, or \
      configure a different HTTP client.
      """

    with {:error, reason} <- Application.ensure_all_started(:finch) do
      raise "failed to start the :finch application: #{inspect(reason)}"
    end
  end

  defp ensure_started!(_client), do: :ok
end
