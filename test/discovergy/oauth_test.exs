defmodule Discovergy.OAuthTest do
  use Discovergy.Case, async: true

  test "login", %{client: client} do
    mock(&full_authorization/1)

    assert {:ok, %Discovergy.Client{consumer: consumer, token: token}} =
             Discovergy.Client.login(client, "$email", "$password")

    assert %Discovergy.OAuth.Consumer{
             attributes: %{},
             key: "$key",
             owner: "$client_id",
             principal: nil,
             secret: "$secret"
           } == consumer

    assert %Discovergy.OAuth.Token{
             oauth_token: "$access_token",
             oauth_token_secret: "$access_token_secret"
           } == token
  end

  test "does not reuse the consumer", %{client: client} do
    mock(&full_authorization/1)

    consumer = %Discovergy.OAuth.Consumer{
      attributes: %{},
      key: "$key",
      owner: "DiscoX",
      principal: nil,
      secret: "$secret"
    }

    assert {:ok, %Discovergy.Client{consumer: new_consumer}} =
             put_in(client.consumer, consumer)
             |> Discovergy.Client.login("$email", "$password")

    assert new_consumer != consumer
  end

  @tag :logged_in
  test "signs in again without the credentials of the previous session", %{client: client} do
    test_pid = self()

    mock(fn response ->
      send(test_pid, {URI.parse(response.url).path, authorization(response.headers)})
      full_authorization(response)
    end)

    assert {:ok, %Discovergy.Client{}} = Discovergy.Client.login(client, "$email", "$password")

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

    assert {:ok, %Discovergy.Client{consumer: consumer, token: token}} =
             Discovergy.Client.reauthorize(client, "$email", "$password")

    assert consumer == client.consumer

    assert %Discovergy.OAuth.Token{
             oauth_token: "$access_token",
             oauth_token_secret: "$access_token_secret"
           } == token

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

    assert {:ok, %Discovergy.Client{}} =
             Discovergy.Client.reauthorize(client, "$email", "$password")

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
               Discovergy.Client.reauthorize(client, "$email", "$password")
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
               Discovergy.Client.reauthorize(client, "$email", "$password")
    end
  end

  test "refuses to reauthorize a client that is not signed in", %{client: client} do
    assert {:error, %Discovergy.Error{reason: :not_logged_in}} =
             Discovergy.Client.reauthorize(client, "$email", "$password")
  end

  defp authorization(headers) do
    Enum.find_value(headers, fn {key, value} ->
      if String.downcase(key) == "authorization", do: value
    end)
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
