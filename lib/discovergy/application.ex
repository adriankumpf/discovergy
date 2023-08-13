defmodule Discovergy.Application do
  @moduledoc false

  use Application

  alias Discovergy.Config

  @impl true
  def start(_type, _opts) do
    client = Config.client()
    pool_opts = Config.client_pool_opts()

    if client == Discovergy.HTTPClient.Finch do
      unless Code.ensure_loaded?(Finch) do
        raise """
        Discovergy failed to start. Add :finch to your dependencies to fix this, or \
        configure a different HTTP client.
        """
      end

      with {:error, reason} <- Application.ensure_all_started(:finch) do
        raise "failed to start the :finch application: #{inspect(reason)}"
      end
    end

    children =
      case client.child_spec(pool_opts) do
        nil -> []
        client -> [client]
      end

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Discovergy.Supervisor
    )
  end
end
