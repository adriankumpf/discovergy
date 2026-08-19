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
  test "refreshes the token without registering another consumer", %{client: client} do
    test_pid = self()

    mock(fn response ->
      send(test_pid, {:path, URI.parse(response.url).path})
      full_authorization(response)
    end)

    assert {:ok, %Discovergy.Client{consumer: consumer, token: token}} =
             Discovergy.Client.refresh(client, "$email", "$password")

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
  test "opens the refresh flow with the right credentials", %{client: client} do
    test_pid = self()

    mock(fn response ->
      send(test_pid, {URI.parse(response.url).path, authorization(response.headers)})
      full_authorization(response)
    end)

    assert {:ok, %Discovergy.Client{}} = Discovergy.Client.refresh(client, "$email", "$password")

    # Signed in already, but this one still has to go out unsigned.
    assert_receive {"/public/v1/oauth1/authorize", nil}

    # Signed as the consumer, and never with the access token being replaced.
    assert_receive {"/public/v1/oauth1/request_token", auth}
    assert auth =~ "oauth_consumer_key="
    refute auth =~ "oauth_token="
  end

  test "refuses to refresh a client that is not signed in", %{client: client} do
    assert {:error, %Discovergy.Error{reason: :not_logged_in}} =
             Discovergy.Client.refresh(client, "$email", "$password")
  end

  defp authorization(headers) do
    Enum.find_value(headers, fn {key, value} ->
      if String.downcase(key) == "authorization", do: value
    end)
  end

  defp full_authorization(response) do
    # Test body
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
