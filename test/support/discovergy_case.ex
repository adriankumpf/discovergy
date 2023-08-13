defmodule Discovergy.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Discovergy.Case
    end
  end

  setup tags do
    opts =
      if tags[:logged_in] do
        consumer = %Discovergy.OAuth.Consumer{
          attributes: %{},
          key: "$key",
          owner: "$client_id",
          secret: "$secret"
        }

        token = %Discovergy.OAuth.Token{
          oauth_token: "$access_token",
          oauth_token_secret: "$access_token_secret"
        }

        [consumer: consumer, token: token]
      else
        []
      end

    client = Discovergy.Client.new([http_client: TestClient] ++ opts)

    {:ok, client: client}
  end

  def mock(fun) do
    Process.put(:request_mock, fn method, url, headers, body, req_opts ->
      uri = URI.parse(url)
      url = put_in(uri.query, nil) |> URI.to_string()

      query =
        if is_binary(uri.query) do
          uri.query
          |> URI.query_decoder()
          |> Enum.map(fn {key, val} -> {String.to_atom(key), val} end)
        end

      response = %{
        method: method,
        url: url,
        query: query,
        headers: headers,
        body: body,
        req_opts: req_opts
      }

      fun.(response)
    end)
  end

  def json(data) do
    {:ok, 200, [{"content-type", "application/json"}], Jason.encode!(data)}
  end

  def form(data) do
    {:ok, 200, [{"content-type", "application/x-www-form-urlencoded"}], URI.encode_query(data)}
  end
end
