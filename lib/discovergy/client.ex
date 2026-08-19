defmodule Discovergy.Client do
  @moduledoc """
  A Discovergy API Client

  Access tokens expire, and an expired one comes back as a `401` with an empty
  body. Use `reauthorize/3` rather than `login/3` to get a new one: the API
  rate limits consumer registration and asks clients to reuse tokens.

  See [Quirks of the API](api-quirks.md) for the behaviour this library has to
  work around.
  """

  alias Discovergy.{Config, Error, OAuth}

  @base_url "https://api.inexogy.com/public/v1"
  @user_agent "github.com/adriankumpf/discovergy"
  @form_urlencoded "application/x-www-form-urlencoded"

  @opaque t :: %__MODULE__{}

  @enforce_keys [:base_url, :http_client]
  defstruct [:base_url, :http_client, :consumer, :token]

  @doc """
  Creates a new Discovergy API client.

  ## Options

  - `:base_url` - the base URL for all endpoints (default: `#{@base_url}`)
  - `:http_client` - a module implementing the `Discovergy.HTTPClient`
    behaviour (default: the `:client` application environment setting)

  ## Examples

      iex> client = Discovergy.Client.new()
      %Discovergy.Client{}

  """
  @spec new(Keyword.t()) :: t
  def new(opts \\ []) do
    %__MODULE__{
      base_url: opts[:base_url] || @base_url,
      http_client: opts[:http_client] || Config.client(),
      consumer: opts[:consumer],
      token: opts[:token]
    }
  end

  @doc """
  Authenticate with the Discovergy API using the email address and password of
  the user.

  ## Examples

      iex> {:ok, client} = Discovergy.Client.new()
      ...>                 |> Discovergy.Client.login(email, password)
      {:ok, %Discovergy.Client{}}

  """
  @spec login(t, String.t(), String.t()) :: {:ok, t} | {:error, Error.t()}
  def login(%__MODULE__{} = client, email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, {consumer, token}} <- OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | token: token, consumer: consumer}}
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

  ## Examples

      iex> {:ok, client} = Discovergy.Client.reauthorize(client, email, password)
      {:ok, %Discovergy.Client{}}

  """
  @spec reauthorize(t, String.t(), String.t()) :: {:ok, t} | {:error, Error.t()}
  def reauthorize(%__MODULE__{consumer: nil}, email, password)
      when is_binary(email) and is_binary(password) do
    {:error, %Error{reason: :not_logged_in}}
  end

  def reauthorize(%__MODULE__{consumer: consumer} = client, email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, token} <- OAuth.reauthorize(client, consumer, email, password) do
      {:ok, %__MODULE__{client | token: token}}
    end
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
    consumer = Keyword.get(opts, :consumer, client.consumer)
    token = Keyword.get(opts, :token, client.token)

    headers =
      sign(method, url, body, consumer, token) ++
        [{"user-agent", @user_agent}, {"content-type", @form_urlencoded}]

    client.http_client.request(
      method,
      url,
      headers,
      URI.encode_query(body),
      Config.client_request_opts()
    )
    |> handle_response()
  end

  defp sign(_method, _url, _body, nil = _consumer, _token), do: []

  defp sign(method, url, body, consumer, token) do
    credentials =
      OAuther.credentials(
        consumer_key: consumer.key,
        consumer_secret: consumer.secret,
        token: token && token.oauth_token,
        token_secret: token && token.oauth_token_secret
      )

    {header, _req_params} =
      OAuther.sign(to_string(method), url, body, credentials) |> OAuther.header()

    [header]
  end

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
