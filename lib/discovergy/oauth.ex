defmodule Discovergy.OAuth do
  @moduledoc false

  alias Discovergy.Client

  @client_id "DiscoX"

  def login(%Client{} = client, email, password) do
    with {:ok, consumer_token} <- get_consumer_token(client, @client_id),
         {:ok, request_token} <- get_request_token(client, consumer_token),
         {:ok, grant} <- authorize(client, request_token, email, password),
         {:ok, access_token} <- get_access_token(client, consumer_token, request_token, grant) do
      {:ok, {consumer_token, access_token}}
    end
  end

  defmodule ConsumerToken do
    defstruct [:attributes, :key, :owner, :principal, :secret]
  end

  @consumer_token_endpoint "/oauth1/consumer_token"
  defp get_consumer_token(%Client{tesla_client: client}, client_id) do
    response = Tesla.post(client, @consumer_token_endpoint, %{client: client_id})

    with {:ok, body} <- handle_response(response) do
      consumer_token = %ConsumerToken{
        attributes: body["attributes"],
        key: body["key"],
        owner: body["owner"],
        principal: body["principal"],
        secret: body["secret"]
      }

      {:ok, consumer_token}
    end
  end

  defmodule RequestToken do
    defstruct [:oauth_callback_confirmed, :oauth_token, :oauth_token_secret]
  end

  @request_token_endpoint "/oauth1/request_token"
  defp get_request_token(%Client{} = client, %ConsumerToken{} = consumer_token) do
    url = client.base_url <> @request_token_endpoint

    credentials =
      OAuther.credentials(
        consumer_key: consumer_token.key,
        consumer_secret: consumer_token.secret
      )

    {authorization_header, req_params} =
      OAuther.sign("post", url, [], credentials)
      |> OAuther.header()

    response =
      Tesla.post(client.tesla_client, @request_token_endpoint, req_params,
        headers: [authorization_header]
      )

    with {:ok, body} <- handle_response(response) do
      request_token = %RequestToken{
        oauth_callback_confirmed: body["oauth_callback_confirmed"],
        oauth_token: body["oauth_token"],
        oauth_token_secret: body["oauth_token_secret"]
      }

      {:ok, request_token}
    end
  end

  defmodule Grant do
    defstruct [:oauth_verifier]
  end

  @authorize_endpoint "/oauth1/authorize"
  defp authorize(%Client{} = client, %RequestToken{} = request_token, email, password) do
    query = [email: email, password: password, oauth_token: request_token.oauth_token]

    with response = Tesla.get(client.tesla_client, @authorize_endpoint, query: query),
         {:ok, body} <- handle_response(response) do
      {:ok, %Grant{oauth_verifier: body["oauth_verifier"]}}
    end
  end

  defmodule AccessToken do
    defstruct [:oauth_token, :oauth_token_secret]
  end

  @access_token_endpoint "/oauth1/access_token"
  def get_access_token(client, consumer_token, request_token, grant) do
    url = client.base_url <> @access_token_endpoint

    credentials =
      OAuther.credentials(
        consumer_key: consumer_token.key,
        consumer_secret: consumer_token.secret,
        token: request_token.oauth_token,
        token_secret: request_token.oauth_token_secret
      )

    {authorization_header, req_params} =
      OAuther.sign("post", url, [{"oauth_verifier", grant.oauth_verifier}], credentials)
      |> OAuther.header()

    response =
      Tesla.post(client.tesla_client, @access_token_endpoint, req_params,
        headers: [authorization_header]
      )

    with {:ok, body} <- handle_response(response) do
      access_token = %AccessToken{
        oauth_token: body["oauth_token"],
        oauth_token_secret: body["oauth_token_secret"]
      }

      {:ok, access_token}
    end
  end

  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}), do: {:ok, body}
  defp handle_response({:ok, %Tesla.Env{} = env}), do: raise("unimplemented! #{inspect(env)}}")
  defp handle_response({:error, reason}), do: {:error, reason}
end
