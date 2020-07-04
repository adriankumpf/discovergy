defmodule Discovergy.Client do
  @moduledoc """
  """

  alias Discovergy.{OAuth, Error}

  @opaque t :: %__MODULE__{}

  @enforce_keys [:tesla_client, :base_url]
  defstruct [:tesla_client, :base_url, :consumer_token, :access_token]

  @base_url "https://api.discovergy.com/public/v1"
  @adapter Tesla.Adapter.Hackney

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

  @spec login(t, String.t(), String.t()) :: {:ok, t} | {:error, Error.t()}
  def login(%__MODULE__{} = client, email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, {consumer_token, access_token}} <- OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | access_token: access_token, consumer_token: consumer_token}}
    end
  end
end
