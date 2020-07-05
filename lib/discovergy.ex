defmodule Discovergy do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @external_resource "README.md"

  defmacro __using__(_opts) do
    quote do
      alias Discovergy.{Client, Error}

      @spec request(Client.t(), atom(), String.t(), Keyword.t(), Keyword.t()) ::
              {:ok, any()} | {:error, Error.t()}
      defp request(%Client{} = client, method, path, body \\ [], opts \\ []) do
        opts =
          opts
          |> Keyword.put_new(:consumer, client.consumer_token)
          |> Keyword.put_new(:token, client.access_token)

        client.tesla_client
        |> Tesla.request(method: method, url: path, body: body, opts: opts)
        |> handle_response()
      end

      defp handle_response(response) do
        case response do
          {:ok, %Tesla.Env{status: 200, body: body}} ->
            {:ok, body}

          {:ok, %Tesla.Env{status: status, body: body} = env}
          when is_binary(body) and body != "" ->
            {:error, %Error{reason: body, env: env}}

          {:ok, %Tesla.Env{} = env} ->
            {:error, %Error{reason: :unkown, env: env}}

          {:error, reason} ->
            {:error, %Error{reason: reason}}
        end
      end
    end
  end
end
