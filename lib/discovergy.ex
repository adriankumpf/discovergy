defmodule Discovergy do
  @moduledoc """
  Documentation for `Discovergy`.
  """

  defmacro __using__(_opts) do
    quote do
      defp request(%Discovergy.Client{} = client, method, path, body \\ [], opts \\ []) do
        uri = URI.parse(client.base_url <> path)
        query = opts[:query] && URI.encode_query(opts[:query])
        url = URI.to_string(%URI{uri | query: query})

        credentials =
          OAuther.credentials(
            consumer_key: client.consumer_token.key,
            consumer_secret: client.consumer_token.secret,
            token: client.access_token.oauth_token,
            token_secret: client.access_token.oauth_token_secret
          )

        {authorization_header, req_params} =
          OAuther.sign(to_string(method), url, body, credentials)
          |> OAuther.header()

        options =
          [
            method: method,
            url: path,
            headers: [authorization_header],
            body: req_params
          ]
          |> Keyword.merge(opts)

        Tesla.request(client.tesla_client, options)
      end
    end
  end
end
