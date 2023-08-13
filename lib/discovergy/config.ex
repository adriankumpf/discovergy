defmodule Discovergy.Config do
  @moduledoc false

  def client, do: Application.get_env(:discovergy, :client, Discovergy.HTTPClient.Finch)
  def client_pool_opts, do: Application.get_env(:discovergy, :client_pool_opts, [])
  def client_request_opts, do: Application.get_env(:discovergy, :client_request_opts, [])
end
