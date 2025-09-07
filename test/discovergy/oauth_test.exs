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
