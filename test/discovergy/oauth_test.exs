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

  test "does not resuse the consumer" do
    mock(&full_authorization/1)

    consumer = %Discovergy.OAuth.Consumer{
      attributes: %{},
      key: "$key",
      owner: "DiscoX",
      principal: nil,
      secret: "$secret"
    }

    assert {:ok, %Discovergy.Client{consumer: new_consumer}} =
             Discovergy.Client.new(adapter: Tesla.Mock, consumer: consumer)
             |> Discovergy.Client.login("$email", "$password")

    assert new_consumer != consumer
  end

  defp full_authorization(%Tesla.Env{} = env) do
    case env do
      %Tesla.Env{method: :post, url: "https://api.discovergy.com/public/v1/oauth1/consumer_token"} ->
        json(%{key: "$key", secret: "$secret", owner: "$client_id", attributes: %{}})

      %Tesla.Env{method: :post, url: "https://api.discovergy.com/public/v1/oauth1/request_token"} ->
        text(
          "oauth_token=$oauth_token&oauth_token_secret=$oauth_token_secret&oauth_callback_confirmed=true",
          headers: [{"content-type", "application/x-www-form-urlencoded"}]
        )

      %Tesla.Env{method: :get, url: "https://api.discovergy.com/public/v1/oauth1/authorize"} ->
        text("oauth_verifier=$oauth_verifier",
          headers: [{"content-type", "application/x-www-form-urlencoded"}]
        )

      %Tesla.Env{method: :post, url: "https://api.discovergy.com/public/v1/oauth1/access_token"} ->
        text(
          "oauth_token=$access_token&oauth_token_secret=$access_token_secret",
          headers: [{"content-type", "application/x-www-form-urlencoded"}]
        )
    end
  end
end
