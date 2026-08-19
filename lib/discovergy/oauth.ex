defmodule Discovergy.OAuth do
  @moduledoc false

  alias Discovergy.Client

  @client_id "DiscoX"

  @doc """
  Registers the client application, obtains and authorizes a request token and
  finally obtains an access token.
  """
  @spec login(Client.t(), String.t(), String.t()) ::
          {:ok, {Consumer.t(), Token.t()}} | {:error, Error.t()}
  def login(%Client{} = client, email, password) do
    with {:ok, consumer} <- register_consumer(client, @client_id),
         {:ok, access_token} <- reauthorize(client, consumer, email, password) do
      {:ok, {consumer, access_token}}
    end
  end

  defmodule Consumer do
    @moduledoc false

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
    @moduledoc false

    use Discovergy.Model

    @type t() :: %__MODULE__{
            oauth_token: String.t(),
            oauth_token_secret: String.t()
          }

    defstruct [:oauth_token, :oauth_token_secret]
  end

  defmodule Grant do
    @moduledoc false

    use Discovergy.Model

    @opaque t() :: %__MODULE__{}

    defstruct [:oauth_verifier]
  end

  @doc """
  Authorization steps 2 to 4, for a consumer that is already registered.
  """
  @spec reauthorize(Client.t(), Consumer.t(), String.t(), String.t()) ::
          {:ok, Token.t()} | {:error, Error.t()}
  def reauthorize(%Client{} = client, %Consumer{} = consumer, email, password) do
    with {:ok, request_token} <- get_request_token(client, consumer),
         {:ok, grant} <- authorize(client, request_token, email, password) do
      get_access_token(client, consumer, request_token, grant)
    end
  end

  @doc """
  Authorization step 1

  See the [OAuth 1.0 specification](https://tools.ietf.org/html/rfc5849) for details.
  """
  @spec register_consumer(Client.t(), String.t()) :: {:ok, Consumer.t()} | {:error, Error.t()}
  def register_consumer(%Client{} = client, client_id) do
    opts = [consumer: nil, token: nil]

    with {:ok, consumer} <-
           Client.post(client, "/oauth1/consumer_token", [{"client", client_id}], opts) do
      {:ok, Consumer.into(consumer)}
    end
  end

  @doc """
  Authorization step 2

  See the [OAuth 1.0 specification](https://tools.ietf.org/html/rfc5849) for details.
  """
  @spec get_request_token(Client.t(), Consumer.t()) :: {:ok, Token.t()} | {:error, Error.t()}
  def get_request_token(%Client{} = client, %Consumer{} = consumer) do
    with {:ok, body} <-
           Client.post(client, "/oauth1/request_token", [], consumer: consumer, token: nil) do
      {:ok, Token.into(URI.decode_query(body))}
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

    opts = [query: query, consumer: nil, token: nil]

    with {:ok, body} <- Client.get(client, "/oauth1/authorize", opts) do
      {:ok, Grant.into(URI.decode_query(body))}
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

    with {:ok, response} <- Client.post(client, "/oauth1/access_token", body, opts) do
      {:ok, Token.into(URI.decode_query(response))}
    end
  end
end
