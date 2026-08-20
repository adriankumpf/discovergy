defmodule Discovergy.Case do
  use ExUnit.CaseTemplate

  alias Discovergy.OAuth
  alias Discovergy.OAuth.{Consumer, Token}

  @oauth %OAuth{
    consumer: %Consumer{attributes: %{}, key: "$key", owner: "$client_id", secret: "$secret"},
    token: %Token{oauth_token: "$access_token", oauth_token_secret: "$access_token_secret"}
  }

  using do
    quote do
      import Discovergy.Case
    end
  end

  # Tag a test or a test module with `:logged_in` to get a client that signs
  # its requests.
  setup tags do
    credentials = if tags[:logged_in], do: [credentials: @oauth], else: []

    {:ok, client: Discovergy.Client.new([http_client: TestClient] ++ credentials)}
  end

  def mock(fun) do
    Process.put(:request_mock, fn method, url, headers, body, req_opts ->
      uri = URI.parse(url)

      query =
        if uri.query do
          for {key, value} <- URI.query_decoder(uri.query), do: {String.to_atom(key), value}
        end

      fun.(%{
        method: method,
        url: URI.to_string(%{uri | query: nil}),
        query: query,
        headers: headers,
        body: body,
        req_opts: req_opts
      })
    end)

    :ok
  end

  def authorization(headers) do
    with {_name, value} <- List.keyfind(headers, "authorization", 0), do: value
  end

  def json(data) do
    {:ok, 200, [{"content-type", "application/json; charset=utf-8"}], Jason.encode!(data)}
  end

  def form(data) do
    text(URI.encode_query(data), "application/x-www-form-urlencoded")
  end

  def text(body, content_type \\ "text/plain") do
    {:ok, 200, [{"content-type", content_type}], body}
  end
end
