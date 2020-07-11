defmodule Discovergy.Client do
  @moduledoc """
  A Discovergy API Client
  """

  alias Discovergy.{OAuth, Error}

  @opaque t :: %__MODULE__{}

  @enforce_keys [:tesla_client, :base_url]
  defstruct [:tesla_client, :base_url, :consumer, :token]

  @base_url "https://api.discovergy.com/public/v1"
  @adapter {Tesla.Adapter.Hackney, pool: :default}

  @doc """
  Creates a new Discovergy API client.

  ## Options

    * `:consumer` - a custom consumer token (see `Discovergy.OAuth.Consumer`)
    * `:token` - a custom access token (see `Discovergyee.OAuth.Token`)
    * `:base_url` - the base URL for all endpoints (default: `#{@base_url}`)
    * `:adapter` - the [Tesla adapter](https://hexdoks.pm/tesla/readme.html)
    for the API client (default: `#{inspect(@adapter)}`)

  ## Examples

      iex> client = Discovergy.Client.new()
      %Discovergy.Client{}

  """
  @spec new(Keyword.t()) :: t
  def new(opts \\ []) do
    base_url = opts[:base_url] || @base_url
    adapter = opts[:adapter] || @adapter
    consumer = opts[:consumer]
    token = opts[:token]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [{"user-agent", "github.com/adriankumpf/discovergy"}]},
      Discovergy.OAuth.Middleware,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.JSON
    ]

    tesla_client = Tesla.client(middlewares, adapter)

    %__MODULE__{
      tesla_client: tesla_client,
      base_url: base_url,
      consumer: consumer,
      token: token
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
    with client = %__MODULE__{client | token: nil},
         {:ok, {consumer, token}} <- OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | token: token, consumer: consumer}}
    end
  end
end
