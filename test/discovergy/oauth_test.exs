defmodule Discovergy.OAuthTest do
  use Discovergy.Case, async: true

  alias Discovergy.{Client, OAuth}

  test "login", %{client: client} do
    mock(&full_authorization/1)

    assert {:ok, client} = Client.login(client, "$email", "$password")

    assert %OAuth{
             consumer: %OAuth.Consumer{
               attributes: %{},
               key: "$key",
               owner: "$client_id",
               principal: nil,
               secret: "$secret"
             },
             token: %OAuth.Token{
               oauth_token: "$access_token",
               oauth_token_secret: "$access_token_secret"
             }
           } == Client.credentials(client)
  end

  test "does not reuse the consumer" do
    mock(&full_authorization/1)

    stale = %OAuth{consumer: %OAuth.Consumer{key: "$stale_key", secret: "$stale_secret"}}
    client = Client.new(http_client: TestClient, credentials: stale)

    assert {:ok, client} = Client.login(client, "$email", "$password")
    assert %OAuth{consumer: consumer} = Client.credentials(client)
    assert consumer != stale.consumer
  end

  @tag :logged_in
  test "signs in again without the credentials of the previous session", %{client: client} do
    test_pid = self()

    mock(fn response ->
      send(test_pid, {URI.parse(response.url).path, authorization(response.headers)})
      full_authorization(response)
    end)

    assert {:ok, %Client{}} = Client.login(client, "$email", "$password")

    # These two open the flow, so there is nothing to sign them with yet.
    assert_receive {"/public/v1/oauth1/consumer_token", nil}
    assert_receive {"/public/v1/oauth1/authorize", nil}
  end

  @tag :logged_in
  test "reauthorizes without registering another consumer", %{client: client} do
    test_pid = self()

    mock(fn response ->
      send(test_pid, {:path, URI.parse(response.url).path})
      full_authorization(response)
    end)

    assert %OAuth{consumer: consumer} = Client.credentials(client)
    assert {:ok, renewed} = Client.reauthorize(client, "$email", "$password")

    assert %OAuth{
             consumer: ^consumer,
             token: %OAuth.Token{
               oauth_token: "$access_token",
               oauth_token_secret: "$access_token_secret"
             }
           } = Client.credentials(renewed)

    assert_receive {:path, "/public/v1/oauth1/request_token"}
    assert_receive {:path, "/public/v1/oauth1/authorize"}
    assert_receive {:path, "/public/v1/oauth1/access_token"}

    # The point of the whole exercise: the API rate limits this one.
    refute_receive {:path, "/public/v1/oauth1/consumer_token"}
  end

  @tag :logged_in
  test "opens the reauthorization flow with the right credentials", %{client: client} do
    test_pid = self()

    mock(fn response ->
      send(test_pid, {URI.parse(response.url).path, authorization(response.headers)})
      full_authorization(response)
    end)

    assert {:ok, %Client{}} = Client.reauthorize(client, "$email", "$password")

    # Signed in already, but this one still has to go out unsigned.
    assert_receive {"/public/v1/oauth1/authorize", nil}

    # Signed as the consumer, and never with the access token being replaced.
    assert_receive {"/public/v1/oauth1/request_token", auth}
    assert auth =~ "oauth_consumer_key="
    refute auth =~ "oauth_token="
  end

  for status <- [400, 401] do
    @tag :logged_in
    test "reports a consumer rejected with an empty #{status} as such", %{client: client} do
      mock(fn %{url: "https://api.inexogy.com/public/v1/oauth1/request_token"} ->
        {:ok, unquote(status), [], ""}
      end)

      assert {:error,
              %Discovergy.Error{reason: :consumer_rejected, response: {unquote(status), [], ""}}} =
               Client.reauthorize(client, "$email", "$password")
    end
  end

  # Only the empty-bodied ones are the consumer. Anything the API bothered to
  # explain keeps its explanation.
  for {status, body} <- [
        {400, "400 Bad Request: something else entirely"},
        {429, "429 Too Many Requests: Rate of authorize requests is too high."}
      ] do
    @tag :logged_in
    test "leaves a request_token #{status} that has a body alone", %{client: client} do
      mock(fn %{url: "https://api.inexogy.com/public/v1/oauth1/request_token"} ->
        {:ok, unquote(status), [{"content-type", "text/plain"}], unquote(body)}
      end)

      assert {:error, %Discovergy.Error{reason: unquote(body)}} =
               Client.reauthorize(client, "$email", "$password")
    end
  end

  test "refuses to reauthorize a client that is not signed in", %{client: client} do
    assert {:error, %Discovergy.Error{reason: :not_logged_in}} =
             Client.reauthorize(client, "$email", "$password")
  end

  # Replies to each of the four steps of the flow. A step that sends something
  # other than what it should falls through and raises CaseClauseError.
  defp full_authorization(response) do
    case {response.method, response.url, response.body} do
      {:post, "https://api.inexogy.com/public/v1/oauth1/consumer_token", "client=DiscoX"} ->
        json(%{key: "$key", secret: "$secret", owner: "$client_id", attributes: %{}})

      {:post, "https://api.inexogy.com/public/v1/oauth1/request_token", ""} ->
        form(
          oauth_callback_confirmed: "true",
          oauth_token: "$oauth_token",
          oauth_token_secret: "$oauth_token_secret"
        )

      {:get, "https://api.inexogy.com/public/v1/oauth1/authorize", ""} ->
        form(oauth_verifier: "$oauth_verifier")

      {:post, "https://api.inexogy.com/public/v1/oauth1/access_token",
       "oauth_verifier=%24oauth_verifier"} ->
        form(oauth_token: "$access_token", oauth_token_secret: "$access_token_secret")
    end
  end
end
