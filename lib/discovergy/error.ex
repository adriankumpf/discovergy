defmodule Discovergy.Error do
  @moduledoc """
  A Discovergy Error

  `:reason` is the message returned by the API, an exception raised by the HTTP
  client, or `{:http_error, status}` if the API replied with an unsuccessful
  status and an empty body. `:response` holds the raw HTTP response, or `nil`
  if the request never got that far.

  Two reasons come from this library rather than from the API:

  - `:not_logged_in` - `Discovergy.Client.reauthorize/3` was called on a client
    that has no consumer, so there is nothing to reuse.
  - `:consumer_rejected` - the API no longer accepts the consumer of the client
    being reauthorized. Register a new one with `Discovergy.Client.login/3`.
  """

  alias Discovergy.HTTPClient

  @type response :: {HTTPClient.status(), HTTPClient.headers(), HTTPClient.body()}

  @type t :: %__MODULE__{reason: term(), response: response() | nil}

  defexception [:reason, :response]

  @impl true
  def message(%__MODULE__{reason: reason}) when is_binary(reason), do: reason
  def message(%__MODULE__{reason: {:http_error, status}}), do: "HTTP #{status}"
  def message(%__MODULE__{reason: :not_logged_in}), do: "not logged in"
  def message(%__MODULE__{reason: :consumer_rejected}), do: "the consumer was rejected"

  def message(%__MODULE__{reason: %{__exception__: true} = reason}) do
    Exception.message(reason)
  end

  def message(%__MODULE__{reason: reason}) do
    inspect(reason)
  end
end
