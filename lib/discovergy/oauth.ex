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

  @type t() :: %__MODULE__{consumer: Consumer.t(), token: Token.t() | nil}

  @enforce_keys [:consumer]
  defstruct [:consumer, :token]

  @doc """
  Runs the four steps of the [OAuth 1.0 flow](https://tools.ietf.org/html/rfc5849):
  register the client application, obtain a request token, authorize it with
  the user's credentials and exchange it for an access token.
  """
  @spec login(Client.t(), String.t(), String.t()) :: {:ok, t()} | {:error, Error.t()}
  def login(%Client{} = client, email, password) do
    with {:ok, consumer} <- register_consumer(client) do
      reauthorize(client, consumer, email, password)
    end
  end

  @doc """
  Steps 2 to 4, for a consumer that is already registered. Taking the consumer
  rather than the whole session is the point of the function: it is all that is
  reused.
  """
  @spec reauthorize(Client.t(), Consumer.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, Error.t()}
  def reauthorize(%Client{} = client, %Consumer{} = consumer, email, password) do
    with {:ok, request_token} <- get_request_token(client, consumer),
         {:ok, verifier} <- authorize(client, request_token, email, password),
         {:ok, token} <- get_access_token(client, consumer, request_token, verifier) do
      {:ok, %__MODULE__{consumer: consumer, token: token}}
    end
  end

  @spec authorization(t(), atom(), String.t(), keyword()) :: {String.t(), String.t()}
  def authorization(%__MODULE__{consumer: consumer, token: token}, method, url, body) do
    credentials =
      OAuther.credentials(
        consumer_key: consumer.key,
        consumer_secret: consumer.secret,
        token: token && token.oauth_token,
        token_secret: token && token.oauth_token_secret
      )

    # OAuther names the header "Authorization"; the rest of the request uses
    # lowercase names, and HTTP does not care which.
    {{_name, value}, _req_params} =
      method |> to_string() |> OAuther.sign(url, body, credentials) |> OAuther.header()

    {"authorization", value}
  end

  defp register_consumer(client) do
    body = [{"client", @client_id}]

    with {:ok, consumer} <-
           Client.post(client, "/oauth1/consumer_token", body, credentials: nil) do
      {:ok, Consumer.into(consumer)}
    end
  end

  defp get_request_token(client, consumer) do
    credentials = %__MODULE__{consumer: consumer}

    case Client.post(client, "/oauth1/request_token", [], credentials: credentials) do
      {:ok, body} ->
        {:ok, Token.into(URI.decode_query(body))}

      # The endpoint takes no parameters of its own, so an empty-bodied 400 or
      # 401 is about the consumer: an unknown key, or a signature that does not
      # check out. A body means the API had something else to say.
      {:error, %Error{reason: {:http_error, status}} = error} when status in [400, 401] ->
        {:error, %Error{error | reason: :consumer_rejected}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp authorize(client, request_token, email, password) do
    query = [email: email, password: password, oauth_token: request_token.oauth_token]

    with {:ok, body} <- Client.get(client, "/oauth1/authorize", query: query, credentials: nil) do
      %{"oauth_verifier" => verifier} = URI.decode_query(body)
      {:ok, verifier}
    end
  end

  defp get_access_token(client, consumer, request_token, verifier) do
    body = [{"oauth_verifier", verifier}]
    credentials = %__MODULE__{consumer: consumer, token: request_token}

    with {:ok, response_body} <-
           Client.post(client, "/oauth1/access_token", body, credentials: credentials) do
      {:ok, Token.into(URI.decode_query(response_body))}
    end
  end
end
