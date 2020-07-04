defmodule Discovergy do
  @moduledoc """
  Documentation for `Discovergy`.
  """

  def request(%Discovergy.Client{} = client, method, path) do
    url = client.base_url <> path

    credentials =
      OAuther.credentials(
        consumer_key: client.consumer_token.key,
        consumer_secret: client.consumer_token.secret,
        token: client.access_token.oauth_token,
        token_secret: client.access_token.oauth_token_secret
      )

    {authorization_header, req_params} =
      OAuther.sign(to_string(method), url, [], credentials)
      |> OAuther.header()

    Tesla.request(client.tesla_client,
      method: method,
      url: path,
      headers: [authorization_header],
      body: req_params
    )
  end
end
