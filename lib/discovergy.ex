defmodule Discovergy do
  @moduledoc """
  Documentation for `Discovergy`.
  """

  defmacro __using__(_opts) do
    quote do
      alias Discovergy.Client

      defp request(%Discovergy.Client{} = client, method, path, body \\ [], opts \\ []) do
        uri = URI.parse(client.base_url <> path)
        query = opts[:query] && URI.encode_query(opts[:query])
        url = URI.to_string(%URI{uri | query: query})

        credentials =
          OAuther.credentials(
            consumer_key: client.consumer_token.key,
            consumer_secret: client.consumer_token.secret,
            token: client.access_token && client.access_token.oauth_token,
            token_secret: client.access_token && client.access_token.oauth_token_secret
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

        client.tesla_client
        |> Tesla.request(options)
        |> handle_response()
      end

      defp handle_response(response) do
        case response do
          {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
          {:ok, %Tesla.Env{} = env} -> raise("unimplemented! #{inspect(env)}}")
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end
end
