defmodule Discovergy.OAuth do
  @moduledoc """
  """

  use Discovergy

  @client_id "DiscoX"

  @doc """
  Registers the client application, obtains and authorizes a request token and
  finally obtains an access token.
  """
  @spec login(Client.t(), String.t(), String.t()) ::
          {:ok, {ConsumerToken.t(), AccessToken.t()}} | {:error, term()}
  def login(%Client{} = client, email, password) do
    with {:ok, consumer_token} <- get_consumer_token(client, @client_id),
         {:ok, request_token} <- get_request_token(client, consumer_token),
         {:ok, grant} <- authorize(client, request_token, email, password),
         {:ok, access_token} <- get_access_token(client, consumer_token, request_token, grant) do
      {:ok, {consumer_token, access_token}}
    end
  end

  defmodule ConsumerToken do
    @moduledoc false

    @opaque t() :: %__MODULE__{}

    defstruct [:attributes, :key, :owner, :principal, :secret]
  end

  @spec get_consumer_token(Client.t(), String.t()) :: {:ok, ConsumerToken.t()} | {:error, term()}
  def get_consumer_token(%Client{tesla_client: client}, client_id) do
    response = Tesla.post(client, "/oauth1/consumer_token", client: client_id)

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
    @moduledoc false

    @opaque t() :: %__MODULE__{}

    defstruct [:oauth_callback_confirmed, :oauth_token, :oauth_token_secret]
  end

  @spec get_request_token(Client.t(), ConsumerToken.t()) ::
          {:ok, RequestToken.t()} | {:error, term()}
  def get_request_token(%Client{} = client, %ConsumerToken{} = consumer_token) do
    client = %Client{client | consumer_token: consumer_token}

    with {:ok, body} <- request(client, :post, "/oauth1/request_token") do
      request_token = %RequestToken{
        oauth_callback_confirmed: body["oauth_callback_confirmed"],
        oauth_token: body["oauth_token"],
        oauth_token_secret: body["oauth_token_secret"]
      }

      {:ok, request_token}
    end
  end

  defmodule Grant do
    @moduledoc false

    @opaque t() :: %__MODULE__{}

    defstruct [:oauth_verifier]
  end

  @spec authorize(Client.t(), RequestToken.t(), String.t(), String.t()) ::
          {:ok, Grant.t()} | {:error, term()}
  def authorize(%Client{} = client, %RequestToken{} = request_token, email, password) do
    query = [email: email, password: password, oauth_token: request_token.oauth_token]
    response = Tesla.get(client.tesla_client, "/oauth1/authorize", query: query)

    with {:ok, body} <- handle_response(response) do
      {:ok, %Grant{oauth_verifier: body["oauth_verifier"]}}
    end
  end

  defmodule AccessToken do
    @moduledoc false

    @opaque t() :: %__MODULE__{}

    defstruct [:oauth_token, :oauth_token_secret]
  end

  @spec get_access_token(Client.t(), ConsumerToken.t(), RequestToken.t(), Grant.t()) ::
          {:ok, AccessToken.t()} | {:error, term()}
  def get_access_token(%Client{} = client, consumer_token, request_token, grant) do
    client = %Client{client | consumer_token: consumer_token, access_token: request_token}
    body = [{"oauth_verifier", grant.oauth_verifier}]

    with {:ok, body} <- request(client, :post, "/oauth1/access_token", body) do
      access_token = %AccessToken{
        oauth_token: body["oauth_token"],
        oauth_token_secret: body["oauth_token_secret"]
      }

      {:ok, access_token}
    end
  end
end
