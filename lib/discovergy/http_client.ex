defmodule Discovergy.HTTPClient do
  @moduledoc """
  Specifies the API for using a custom HTTP Client.

  The default HTTP client is `Discovergy.HTTPClient.Finch`.

  To configure a different HTTP client, implement the `Discovergy.HTTPClient` behaviour
  and change the `:client` configuration:

      config :discovergy, client: MyHTTPClient

  ## Example

  A client implementation based on `:hackney` could look like this:

      defmodule MyHTTPClient do
        @behaviour Discovergy.HTTPClient

        @hackney_pool_name :discovergy_pool

        @impl true
        def child_spec(opts) do
          :hackney_pool.child_spec(@hackney_pool_name, opts)
        end

        @impl true
        def request(method, url, headers, body, opts) do
          opts = Keyword.merge(opts, pool: @hackney_pool_name) ++ [:with_body]

          case :hackney.request(method, url, headers, body, opts) do
            {:ok, _status, _headers, _body} = result -> result
            {:error, _reason} = error -> error
          end
        end
      end

  """

  @typedoc """
  HTTP request method.
  """
  @type method :: atom

  @typedoc """
  HTTP request URL.
  """
  @type url :: String.t()

  @typedoc """
  HTTP response status.
  """
  @type status :: 100..599

  @typedoc """
  HTTP request or response headers.
  """
  @type headers :: [{String.t(), String.t()}]

  @typedoc """
  HTTP request or response body.
  """
  @type body :: binary()

  @typedoc """
  HTTP request options (set via `:client_request_opts`).
  """
  @type req_opts :: Keyword.t()

  @typedoc """
  Options to configure the pool (set via `:client_pool_opts`).
  """
  @type pool_opts :: Keyword.t()

  @doc """
  Should return a **child specification** to start the HTTP client or `nil`.

  For example, this can start a pool of HTTP connections dedicated to Discovergy.
  """
  @callback child_spec(pool_opts) :: Supervisor.child_spec() | nil

  @doc """
  Should make an HTTP request to `url` with the given `method`, `headers`, `body` and `req_opts`.
  """
  @callback request(method, url, headers, body, req_opts) ::
              {:ok, status, headers, body} | {:error, term}
end
