defmodule Discovergy.OAuth do
  @moduledoc false

  alias Discovergy.{Client, Error}

  @client_id "DiscoX"

  defmodule Consumer do
    @moduledoc false

    alias Discovergy.Model

    @type t() :: %__MODULE__{
            attributes: map(),
            key: String.t(),
            owner: String.t(),
            principal: String.t(),
            secret: String.t()
          }

    @derive {Inspect, except: [:secret]}
    defstruct [:attributes, :key, :owner, :principal, :secret]

    def into(attrs), do: Model.cast(__MODULE__, attrs)
  end

  defmodule Token do
    @moduledoc false

    alias Discovergy.Model

    @type t() :: %__MODULE__{
            oauth_token: String.t(),
            oauth_token_secret: String.t()
          }

    @derive {Inspect, except: [:oauth_token_secret]}
    defstruct [:oauth_token, :oauth_token_secret]

    def into(attrs), do: Model.cast(__MODULE__, attrs)
  end

  @doc """
  Runs the four steps of the [OAuth 1.0 flow](https://tools.ietf.org/html/rfc5849):
  register the client application, obtain a request token, authorize it with
  the user's credentials and exchange it for an access token.
  """
  @spec login(Client.t(), String.t(), String.t()) ::
          {:ok, {Consumer.t(), Token.t()}} | {:error, Error.t()}
  def login(%Client{} = client, email, password) do
    with {:ok, consumer} <- register_consumer(client),
         {:ok, access_token} <- reauthorize(client, consumer, email, password) do
      {:ok, {consumer, access_token}}
    end
  end

  @doc """
  Steps 2 to 4, for a consumer that is already registered.
  """
  @spec reauthorize(Client.t(), Consumer.t(), String.t(), String.t()) ::
          {:ok, Token.t()} | {:error, Error.t()}
  def reauthorize(%Client{} = client, %Consumer{} = consumer, email, password) do
    with {:ok, request_token} <- get_request_token(client, consumer),
         {:ok, verifier} <- authorize(client, request_token, email, password) do
      get_access_token(client, consumer, request_token, verifier)
    end
  end

  defp register_consumer(client) do
    opts = [consumer: nil, token: nil]

    with {:ok, consumer} <-
           Client.post(client, "/oauth1/consumer_token", [{"client", @client_id}], opts) do
      {:ok, Consumer.into(consumer)}
    end
  end

  defp get_request_token(client, consumer) do
    with {:ok, body} <-
           Client.post(client, "/oauth1/request_token", [], consumer: consumer, token: nil) do
      {:ok, Token.into(URI.decode_query(body))}
    end
  end

  defp authorize(client, request_token, email, password) do
    query = [email: email, password: password, oauth_token: request_token.oauth_token]
    opts = [query: query, consumer: nil, token: nil]

    with {:ok, body} <- Client.get(client, "/oauth1/authorize", opts) do
      %{"oauth_verifier" => verifier} = URI.decode_query(body)
      {:ok, verifier}
    end
  end

  defp get_access_token(client, consumer, request_token, verifier) do
    body = [{"oauth_verifier", verifier}]
    opts = [consumer: consumer, token: request_token]

    with {:ok, response_body} <- Client.post(client, "/oauth1/access_token", body, opts) do
      {:ok, Token.into(URI.decode_query(response_body))}
    end
  end
end
