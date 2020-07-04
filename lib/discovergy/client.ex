defmodule Discovergy.Client do
  @moduledoc """
  """

  @enforce_keys [:tesla_client, :base_url, :opts]
  defstruct [:tesla_client, :base_url, :opts, :consumer_token, :access_token]

  @base_url "https://api.discovergy.com/public/v1"
  @adapter Tesla.Adapter.Hackney

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

    %__MODULE__{tesla_client: tesla_client, base_url: base_url, opts: opts}
  end

  def login(%__MODULE__{} = client, email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, {consumer_token, access_token}} <- Discovergy.OAuth.login(client, email, password) do
      {:ok, %__MODULE__{client | access_token: access_token, consumer_token: consumer_token}}
    end
  end
end
