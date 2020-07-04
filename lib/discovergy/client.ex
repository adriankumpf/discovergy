defmodule Discovergy.Client do
  @moduledoc """
  A Discovergy API Client.
  """

  alias Discovergy.{OAuth, Error}

  @opaque t :: %__MODULE__{}

  @enforce_keys [:tesla_client, :base_url]
  defstruct [:tesla_client, :base_url, :consumer_token, :access_token]

  @base_url "https://api.discovergy.com/public/v1"
  @adapter Tesla.Adapter.Hackney

  @doc """
  Creates a new Discovergy API client.

  ## Options

    * `:base_url` - the base URL for all endpoints (default:
    `https://api.discovergy.com/public/v1`)
    * `:adapter` - the [Tesla](https://hexdocs.pm/tesla/readme.html) adapter
    for the API client (default: `Tesla.Adapter.Hackney`)

  ## Examples

      iex> client = Discovergy.Client.new()
      %Discovergy.Client{}

  """
  @spec new(Keyword.t()) :: t
  def new(opts \\ []) do
    base_url = opts[:base_url] || @base_url
    adapter = opts[:adapter] || @adapter

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [{"user-agent", ""}]},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.JSON
    ]

    tesla_client = Tesla.client(middlewares, adapter)

    %__MODULE__{tesla_client: tesla_client, base_url: base_url}
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
    with {:ok, {consumer_token, access_token}} <- OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | access_token: access_token, consumer_token: consumer_token}}
    end
  end
end
