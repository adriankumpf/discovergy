defmodule Discovergy.ClientTest do
  use Discovergy.Case, async: true

  alias Discovergy.Client

  setup do
    test_pid = self()

    mock(fn request ->
      send(test_pid, {:request, request})
      json([])
    end)
  end

  test "identifies itself and does not sign requests when logged out", %{client: client} do
    assert {:ok, []} = Client.get(client, "/meters")

    assert_receive {:request, %{headers: headers}}
    assert {"user-agent", "github.com/adriankumpf/discovergy"} in headers
    refute List.keyfind(headers, "Authorization", 0)
  end

  @tag :logged_in
  test "signs requests once logged in", %{client: client} do
    assert {:ok, []} = Client.get(client, "/meters")

    assert_receive {:request, %{headers: headers}}
    assert {"Authorization", "OAuth " <> params} = List.keyfind(headers, "Authorization", 0)
    assert params =~ ~s(oauth_consumer_key="%24key")
    assert params =~ ~s(oauth_token="%24access_token")
    assert params =~ "oauth_signature="
  end

  @tag :logged_in
  test "keeps the credentials out of the inspected client", %{client: client} do
    for inspected <- [inspect(client), inspect(client.consumer), inspect(client.token)] do
      refute inspected =~ client.consumer.secret
      refute inspected =~ client.token.oauth_token_secret
    end
  end

  test "talks to the configured base URL" do
    client = Client.new(base_url: "http://localhost:4000/v1", http_client: TestClient)

    assert {:ok, []} = Client.get(client, "/meters")
    assert_receive {:request, %{url: "http://localhost:4000/v1/meters"}}
  end
end
