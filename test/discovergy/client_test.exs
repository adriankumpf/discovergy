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

  test "identifies itself and does not authenticate requests when logged out", %{client: client} do
    assert {:ok, []} = Client.get(client, "/meters")

    assert_receive {:request, %{headers: headers, body: ""}}
    assert {"user-agent", "github.com/adriankumpf/discovergy"} in headers
    assert authorization(headers) == nil
    refute List.keyfind(headers, "content-type", 0)
  end

  test "form encodes the body of a POST", %{client: client} do
    assert {:ok, []} = Client.post(client, "/oauth1/consumer_token", [{"client", "DiscoX"}])

    assert_receive {:request, %{headers: headers, body: "client=DiscoX"}}
    assert {"content-type", "application/x-www-form-urlencoded"} in headers
  end

  @tag :logged_in
  test "signs requests once logged in", %{client: client} do
    assert {:ok, []} = Client.get(client, "/meters")

    assert_receive {:request, %{headers: headers}}
    assert "OAuth " <> params = authorization(headers)
    assert params =~ ~s(oauth_consumer_key="%24key")
    assert params =~ ~s(oauth_token="%24access_token")
    assert params =~ "oauth_signature="
  end

  test "talks to the configured base URL" do
    client = Client.new(base_url: "http://localhost:4000/v1", http_client: TestClient)

    assert {:ok, []} = Client.get(client, "/meters")
    assert_receive {:request, %{url: "http://localhost:4000/v1/meters"}}
  end

  describe "basic_auth/3" do
    setup %{client: client} do
      {:ok, client: Client.basic_auth(client, "demo@inexogy.com", "demo")}
    end

    test "sends the credentials with every request", %{client: client} do
      assert {:ok, []} = Client.get(client, "/meters")

      assert_receive {:request, %{headers: headers}}
      assert authorization(headers) == "Basic " <> Base.encode64("demo@inexogy.com:demo")
    end

    test "sends nothing to establish the session" do
      refute_receive {:request, _}
    end

    test "has nothing to reauthorize", %{client: client} do
      assert {:error, %Discovergy.Error{reason: :not_logged_in}} =
               Client.reauthorize(client, "demo@inexogy.com", "demo")
    end
  end

  describe "credentials/1" do
    test "are absent until the client authenticates", %{client: client} do
      assert Client.credentials(client) == nil
    end

    @tag :logged_in
    test "restore a session into a new client", %{client: client} do
      restored = Client.new(http_client: TestClient, credentials: Client.credentials(client))

      assert {:ok, []} = Client.get(restored, "/meters")
      assert_receive {:request, %{headers: headers}}
      assert authorization(headers) =~ ~s(oauth_token="%24access_token")
    end
  end

  describe "inspect" do
    @tag :logged_in
    test "keeps the OAuth secrets out of the output", %{client: client} do
      for inspected <- [inspect(client), inspect(Client.credentials(client))] do
        refute inspected =~ "$secret"
        refute inspected =~ "$access_token_secret"
      end
    end

    test "keeps the password out of the output", %{client: client} do
      client = Client.basic_auth(client, "demo@inexogy.com", "hunter2")

      for inspected <- [inspect(client), inspect(Client.credentials(client))] do
        refute inspected =~ "hunter2"
      end
    end
  end
end
