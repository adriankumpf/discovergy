defmodule Discovergy.OAuth do
  @moduledoc """
  The OAuth endpoint

  Normally it is not necessary to call the individual authentication steps
  manually, see `Discovergy.Client.login/3`.
  """

  use Discovergy

  @client_id "DiscoX"

  @doc """
  Registers the client application, obtains and authorizes a request token and
  finally obtains an access token.
  """
  @spec login(Client.t(), String.t(), String.t()) ::
          {:ok, {Consumer.t(), Token.t()}} | {:error, Error.t()}
  def login(%Client{} = client, email, password) do
    with {:ok, consumer} <- register_consumer(client, @client_id),
         {:ok, request_token} <- get_request_token(client, consumer),
         {:ok, grant} <- authorize(client, request_token, email, password),
         {:ok, access_token} <- get_access_token(client, consumer, request_token, grant) do
      {:ok, {consumer, access_token}}
    end
  end

  defmodule Consumer do
    use Discovergy.Model

    @type t() :: %__MODULE__{
            attributes: map(),
            key: String.t(),
            owner: String.t(),
            principal: String.t(),
            secret: String.t()
          }

    defstruct [:attributes, :key, :owner, :principal, :secret]
  end

  defmodule Token do
    use Discovergy.Model

    @type t() :: %__MODULE__{
            oauth_token: String.t(),
            oauth_token_secret: String.t()
          }

    defstruct [:oauth_token, :oauth_token_secret]
  end

  defmodule Grant do
    use Discovergy.Model

    @moduledoc false
    @opaque t() :: %__MODULE__{}

    defstruct [:oauth_verifier]
  end

  @doc """
  Authorization step 1

  See the [OAuth 1.0 specification](https://tools.ietf.org/html/rfc5849) for details.
  """
  @spec register_consumer(Client.t(), String.t()) :: {:ok, Consumer.t()} | {:error, Error.t()}
  def register_consumer(%Client{consumer: %Consumer{owner: client_id} = consumer}, client_id) do
    {:ok, consumer}
  end

  def register_consumer(%Client{tesla_client: client}, client_id) do
    response = Tesla.post(client, "/oauth1/consumer_token", client: client_id)

    with {:ok, consumer} <- handle_response(response) do
      {:ok, Consumer.into(consumer)}
    end
  end

  @doc """
  Authorization step 2

  See the [OAuth 1.0 specification](https://tools.ietf.org/html/rfc5849) for details.
  """
  @spec get_request_token(Client.t(), Consumer.t()) :: {:ok, Token.t()} | {:error, Error.t()}
  def get_request_token(%Client{} = client, %Consumer{} = consumer) do
    with {:ok, request_token} <- post(client, "/oauth1/request_token", [], consumer: consumer) do
      {:ok, Token.into(request_token)}
    end
  end

  @doc """
  Authorization step 3

  See the [OAuth 1.0 specification](https://tools.ietf.org/html/rfc5849) for details.
  """
  @spec authorize(Client.t(), Token.t(), String.t(), String.t()) ::
          {:ok, Grant.t()} | {:error, Error.t()}
  def authorize(%Client{} = client, %Token{} = request_token, email, password) do
    query = [email: email, password: password, oauth_token: request_token.oauth_token]
    response = Tesla.get(client.tesla_client, "/oauth1/authorize", query: query)

    with {:ok, grant} <- handle_response(response) do
      {:ok, Grant.into(grant)}
    end
  end

  @doc """
  Authorization step 4

  See the [OAuth 1.0 specification](https://tools.ietf.org/html/rfc5849) for details.
  """
  @spec get_access_token(Client.t(), Consumer.t(), Token.t(), Grant.t()) ::
          {:ok, Token.t()} | {:error, Error.t()}
  def get_access_token(%Client{} = client, consumer, request_token, grant) do
    body = [{"oauth_verifier", grant.oauth_verifier}]
    opts = [consumer: consumer, token: request_token]

    with {:ok, access_token} <- post(client, "/oauth1/access_token", body, opts) do
      {:ok, Token.into(access_token)}
    end
  end
end
