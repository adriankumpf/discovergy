defmodule Discovergy.Client do
  @moduledoc """
  A Discovergy API Client

  There are two ways to authenticate, and a client uses one of them for its
  lifetime:

  - `login/3` runs the OAuth 1.0a flow the [official
    documentation](https://api.inexogy.com/docs/) describes. Both the access
    token and the consumer behind it expire, so a long-running client renews
    them with `reauthorize/3` and, when that is refused, `login/3`.

  - `basic_auth/3` sends the email and password with every request. Nothing
    expires and nothing is rate limited, but the API documents no such thing.

  See [Quirks of the API](api-quirks.md) for the behaviour this library has to
  work around.
  """

  alias Discovergy.{BasicAuth, Config, Error, OAuth}

  @base_url "https://api.inexogy.com/public/v1"
  @user_agent "github.com/adriankumpf/discovergy"
  @form_urlencoded "application/x-www-form-urlencoded"

  @opaque credentials :: OAuth.t() | BasicAuth.t()

  @opaque t :: %__MODULE__{
            base_url: String.t(),
            http_client: module,
            credentials: credentials | nil
          }

  # The client carries the credentials of the session. Keep them out of logs,
  # crash reports and iex output.
  @derive {Inspect, only: [:base_url]}

  @enforce_keys [:base_url, :http_client]
  defstruct [:base_url, :http_client, :credentials]

  @doc """
  Creates a new Discovergy API client.

  ## Options

  - `:base_url` - the base URL for all endpoints (default: `#{@base_url}`)
  - `:http_client` - a module implementing the `Discovergy.HTTPClient`
    behaviour (default: the `:client` application environment setting)
  - `:credentials` - the credentials of a previous session, as `credentials/1`
    returns them

  Passing `:credentials` restores a session that was persisted elsewhere. For
  an OAuth session that means a restart neither registers another consumer nor
  spends an `authorize` call, both of which are rate limited per IP. The client
  is then usable right away, and `reauthorize/3` works on it once the token
  expires. Basic auth has nothing worth restoring; call `basic_auth/3` instead.

  ## Examples

      iex> Discovergy.Client.new()
      #Discovergy.Client<base_url: "https://api.inexogy.com/public/v1", ...>

  """
  @spec new(Keyword.t()) :: t
  def new(opts \\ []) do
    %__MODULE__{
      base_url: opts[:base_url] || @base_url,
      http_client: opts[:http_client] || Config.client(),
      credentials: opts[:credentials]
    }
  end

  @doc """
  Returns the credentials of the session, or `nil` if the client has none.

  Worth persisting for an OAuth session, which `new/1` takes back to skip the
  two rate limited calls `login/3` would spend after a restart. Serialize it
  with `:erlang.term_to_binary/1`, since the structs redact themselves when
  inspected and encode to no other format, and be ready for a blob written by
  an older version of this library not to load.

  A Basic auth session is worth nothing persisted: `basic_auth/3` rebuilds it
  from the same email and password, and storing it writes the account's
  password somewhere new.

  ## Examples

      iex> Discovergy.Client.new() |> Discovergy.Client.credentials()
      nil

  """
  @spec credentials(t) :: credentials | nil
  def credentials(%__MODULE__{credentials: credentials}), do: credentials

  @doc """
  Authenticate with the Discovergy API using the email address and password of
  the user.

  This runs the OAuth 1.0a flow: it registers a consumer and exchanges the
  credentials for an access token, both of which expire. Use `reauthorize/3` to
  renew the token, or `basic_auth/3` to avoid the lifecycle altogether.

  ## Examples

      iex> {:ok, client} = Discovergy.Client.new()
      ...>                 |> Discovergy.Client.login(email, password)
      {:ok, #Discovergy.Client<base_url: "https://api.inexogy.com/public/v1", ...>}

  """
  @spec login(t, String.t(), String.t()) :: {:ok, t} | {:error, Error.t()}
  def login(%__MODULE__{} = client, email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, oauth} <- OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | credentials: oauth}}
    end
  end

  @doc """
  Obtains a new access token for a client that is already signed in.

  Reuses the consumer registered by `login/3` rather than registering another
  one, which is what the API asks for: it rate limits `consumer_token`
  requests and answers with `429 Too Many Requests: ... Please reuse tokens!`
  once a client registers too often.

  Prefer this over calling `login/3` again when an access token expires. A
  long-running application that signs in once and reauthorizes on every `401`
  registers a single consumer for its lifetime.

  Named for what it does: the API has no credential-free refresh, so this needs
  the user's password just as `login/3` does. Only the consumer is spared.

  A client that has no OAuth session, because it never logged in or because it
  uses `basic_auth/3`, fails with `reason: :not_logged_in`.

  ## When the consumer is gone

  The API drops consumers too, usually at the nightly maintenance that expires
  the token. `reauthorize/3` then fails with `reason: :consumer_rejected`, and
  only `login/3` recovers from it:

      case Discovergy.Client.reauthorize(client, email, password) do
        {:error, %Discovergy.Error{reason: :consumer_rejected}} ->
          Discovergy.Client.login(client, email, password)

        result ->
          result
      end

  `login/3` discards the credentials of the previous session, so hand it the
  same client rather than a new one, which would lose its `:base_url` and
  `:http_client`.

  ## Examples

      iex> {:ok, client} = Discovergy.Client.reauthorize(client, email, password)
      {:ok, #Discovergy.Client<base_url: "https://api.inexogy.com/public/v1", ...>}

  """
  @spec reauthorize(t, String.t(), String.t()) :: {:ok, t} | {:error, Error.t()}
  def reauthorize(%__MODULE__{credentials: %OAuth{consumer: consumer}} = client, email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, oauth} <- OAuth.reauthorize(client, consumer, email, password) do
      {:ok, %__MODULE__{client | credentials: oauth}}
    end
  end

  def reauthorize(%__MODULE__{}, email, password)
      when is_binary(email) and is_binary(password) do
    {:error, %Error{reason: :not_logged_in}}
  end

  @doc """
  Authenticate with HTTP Basic auth, using the email address and password of
  the user.

  Every endpoint accepts the credentials directly, so there is no token to
  expire, no consumer to register and neither of the rate limits `login/3` runs
  into. Nothing is sent here: the client is ready to use, and a wrong password
  surfaces as a `401` on the first request.

  The API documents none of this, so it could be withdrawn without notice.
  `login/3` is the documented way in.

  ## Examples

      iex> Discovergy.Client.new() |> Discovergy.Client.basic_auth(email, password)
      #Discovergy.Client<base_url: "https://api.inexogy.com/public/v1", ...>

  """
  @spec basic_auth(t, String.t(), String.t()) :: t
  def basic_auth(%__MODULE__{} = client, email, password)
      when is_binary(email) and is_binary(password) do
    %__MODULE__{client | credentials: %BasicAuth{email: email, password: password}}
  end

  @doc false
  @spec get(t(), String.t(), Keyword.t()) :: {:ok, term} | {:error, Error.t()}
  def get(%__MODULE__{} = client, path, opts \\ []) do
    request(client, :get, path, [], opts)
  end

  @doc false
  @spec post(t(), String.t(), Keyword.t(), Keyword.t()) :: {:ok, term} | {:error, Error.t()}
  def post(%__MODULE__{} = client, path, body, opts \\ []) do
    request(client, :post, path, body, opts)
  end

  defp request(%__MODULE__{} = client, method, path, body, opts) do
    url = build_url(client.base_url, path, opts[:query] || [])
    credentials = Keyword.get(opts, :credentials, client.credentials)

    headers =
      authorization(credentials, method, url, body) ++
        [{"user-agent", @user_agent} | content_type(method)]

    client.http_client.request(
      method,
      url,
      headers,
      URI.encode_query(body),
      Config.client_request_opts()
    )
    |> handle_response()
  end

  # The API takes its parameters in the query string throughout; only the OAuth
  # endpoints have a body at all, and it is form encoded.
  defp content_type(:post), do: [{"content-type", @form_urlencoded}]
  defp content_type(_method), do: []

  defp authorization(nil, _method, _url, _body), do: []

  defp authorization(%BasicAuth{} = basic, _method, _url, _body),
    do: [BasicAuth.authorization(basic)]

  defp authorization(%OAuth{} = oauth, method, url, body),
    do: [OAuth.authorization(oauth, method, url, body)]

  # Optional parameters are passed as nil rather than dropped at every call
  # site, because the API rejects the ones it does not expect to be empty.
  defp build_url(base_url, path, params) do
    query =
      case Enum.reject(params, &match?({_key, nil}, &1)) do
        [] -> nil
        params -> URI.encode_query(params)
      end

    base_url
    |> URI.parse()
    |> URI.append_path(path)
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  defp handle_response({:ok, status, headers, body}) when status in 200..299 do
    case decode(headers, body) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, %Error{reason: reason, response: {status, headers, body}}}
    end
  end

  defp handle_response({:ok, status, headers, body}) do
    {:error, %Error{reason: reason(status, body), response: {status, headers, body}}}
  end

  defp handle_response({:error, reason}) do
    {:error, %Error{reason: reason}}
  end

  # Everything but the OAuth endpoints replies with JSON. Those reply with a
  # form-encoded body, which the callers decode themselves, because only they
  # know whether the body is a set of parameters or a bare value.
  defp decode(headers, body) do
    if body != "" and json?(headers) do
      Jason.decode(body)
    else
      {:ok, body}
    end
  end

  defp json?(headers) do
    Enum.any?(headers, fn {name, value} ->
      String.downcase(name) == "content-type" and media_type(value) == "application/json"
    end)
  end

  defp media_type(content_type) do
    content_type |> String.split(";", parts: 2) |> hd() |> String.trim() |> String.downcase()
  end

  defp reason(_status, body) when is_binary(body) and body != "", do: body
  defp reason(status, _body), do: {:http_error, status}
end
