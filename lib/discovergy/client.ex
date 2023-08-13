defmodule Discovergy.Client do
  @moduledoc """
  A Discovergy API Client
  """

  alias Discovergy.{Config, OAuth, Error}

  @user_agent "github.com/adriankumpf/discovergy"

  @opaque t :: %__MODULE__{}

  @enforce_keys [:base_url, :http_client]
  defstruct [:base_url, :http_client, :consumer, :token]

  @base_url "https://api.discovergy.com/public/v1"

  @doc """
  Creates a new Discovergy API client.

  ## Options

  - `:base_url` - the base URL for all endpoints (default: `#{@base_url}`)

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
    client = put_in(client.token, nil)

    with {:ok, {consumer, token}} <- OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | token: token, consumer: consumer}}
    end
  end

  @doc false
  @spec get(t(), String.t(), Keyword.t()) :: {:ok, any()} | {:error, Error.t()}
  def get(%__MODULE__{} = client, path, opts \\ []) do
    request(client, :get, path, [], opts)
  end

  @doc false
  @spec post(t(), String.t(), Keyword.t(), Keyword.t()) :: {:ok, any()} | {:error, Error.t()}
  def post(%__MODULE__{} = client, path, body, opts \\ []) do
    request(client, :post, path, body, opts)
  end

  defp request(%__MODULE__{} = client, method, path, body, opts) do
    request = build_request(client, method, path, body, opts)
    run_request(client, request)
  end

  defp run_request(%__MODULE__{http_client: http_client}, request) do
    case http_client.request(
           request.method,
           request.url,
           request.headers,
           request.body,
           request.req_opts
         ) do
      {:ok, 200, headers, body} ->
        {:ok, maybe_decode_body(headers, body)}

      {:ok, status, headers, body}
      when is_binary(body) and body != "" ->
        {:error, %Error{reason: body, response: {status, headers, body}}}

      {:ok, status, headers, body} ->
        {:error, %Error{reason: :unknown, response: {status, headers, body}}}

      {:error, reason} ->
        {:error, %Error{reason: reason}}
    end
  end

  defp build_request(%__MODULE__{} = client, method, path, body, opts) do
    query = opts[:query] || []
    consumer = opts[:consumer] || client.consumer
    token = opts[:token] || client.token

    request = %{
      method: method,
      url: build_url(client.base_url, path, query),
      headers: [{"user-agent", @user_agent}],
      body: body,
      req_opts: Config.client_request_opts()
    }

    request
    |> sign(consumer, token)
    |> encode_body()
  end

  defp sign(request, nil, _token), do: request

  defp sign(request, consumer, token) do
    credentials =
      OAuther.credentials(
        consumer_key: consumer.key,
        consumer_secret: consumer.secret,
        token: token && token.oauth_token,
        token_secret: token && token.oauth_token_secret
      )

    {authorization_header, _req_params} =
      OAuther.sign(to_string(request.method), request.url, request.body, credentials)
      |> OAuther.header()

    update_in(request.headers, &[authorization_header | &1])
  end

  defp build_url(base_url, path, params) do
    query =
      case params do
        [] -> nil
        _ -> URI.encode_query(params)
      end

    base_url
    |> URI.parse()
    |> append_path(path)
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  # Replace with `URI.append_path/2` once Elixir 1.15 is required
  defp append_path(%URI{}, "//" <> _ = path) do
    raise ArgumentError, ~s|path cannot start with "//", got: #{inspect(path)}|
  end

  defp append_path(%URI{path: path} = uri, "/" <> rest = all) do
    cond do
      path == nil -> %{uri | path: all}
      path != "" and :binary.last(path) == ?/ -> %{uri | path: path <> rest}
      true -> %{uri | path: path <> all}
    end
  end

  defp append_path(%URI{}, path) when is_binary(path) do
    raise ArgumentError, ~s|path must start with "/", got: #{inspect(path)}|
  end

  defp encode_body(%{body: body} = request) when not is_nil(body) do
    content_type = {"content-type", "application/x-www-form-urlencoded"}

    request
    |> Map.update!(:headers, &[content_type | &1])
    |> Map.put(:body, URI.encode_query(body))
  end

  defp encode_body(request), do: request

  defp maybe_decode_body(headers, body) do
    cond do
      decodable_body?(body) and decodable_url_encoded_content_type?(headers) ->
        URI.decode_query(body)

      decodable_body?(body) and decodable_json_content_type?(headers) ->
        Jason.decode!(body)

      true ->
        body
    end
  end

  defp decodable_body?(body), do: is_binary(body) and body != ""

  defp decodable_url_encoded_content_type?(headers) do
    case List.keyfind(headers, "content-type", 0) do
      {_, "application/x-www-form-urlencoded"} -> true
      _ -> false
    end
  end

  defp decodable_json_content_type?(headers) do
    case List.keyfind(headers, "content-type", 0) do
      {_, "application/json"} -> true
      _ -> false
    end
  end
end
