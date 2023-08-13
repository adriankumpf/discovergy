defmodule DiscovergyTest do
  use ExUnit.Case, async: false

  alias Discovergy.Client

  defmodule TestClient do
    @behaviour Discovergy.HTTPClient

    @impl true
    def child_spec(pool_opts) do
      send(:discovergy_test, {:child_spec, pool_opts})
      Finch.child_spec(name: __MODULE__)
    end

    @impl true
    def request(_method, _url, _headers, _body, opts) do
      send(:discovergy_test, {:request, opts})
      {:ok, 200, [], []}
    end
  end

  defmodule NoChildSpecTestClient do
    @behaviour Discovergy.HTTPClient

    @impl true
    def child_spec(_pool_opts), do: nil

    @impl true
    def request(_method, _url, _headers, _body, _opts), do: raise("unimplemented")
  end

  @default_config [client: TestClient]

  setup_all do
    Application.stop(:discovergy)

    on_exit(fn ->
      Application.start(:discovergy)
    end)

    :ok
  end

  setup ctx do
    config = Keyword.merge(@default_config, Map.get(ctx, :config, []))

    application_child_spec = %{
      id: __MODULE__,
      start: {Discovergy.Application, :start, [nil, []]},
      type: :supervisor
    }

    Process.register(self(), :discovergy_test)

    for {key, value} <- config do
      Application.put_env(:discovergy, key, value)
    end

    on_exit(fn ->
      for {key, _value} <- Application.get_all_env(:discovergy) do
        Application.delete_env(:discovergy, key)
      end
    end)

    start_supervised!(application_child_spec)

    :ok
  end

  @tag config: [client: NoChildSpecTestClient]
  test "allows to return nil from child_spec/1" do
    :ok
  end

  @tag config: [client_pool_opts: [conn_opts: [proxy: {:http, "127.0.0.1", 8888, []}]]]
  test "passes the :client_pool_opts to child_spec/1" do
    assert_received {:child_spec, [conn_opts: [proxy: {:http, "127.0.0.1", 8888, []}]]}
  end

  @tag config: [client_request_opts: [receive_timeout: 5_000]]
  test "passes the :client_request_opts to request/5" do
    {:ok, _client} = Client.new() |> Client.login("$email", "$password")
    assert_receive {:request, receive_timeout: 5000}
  end
end
