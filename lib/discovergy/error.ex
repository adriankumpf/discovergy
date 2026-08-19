defmodule Discovergy.Error do
  @moduledoc """
  A Discovergy Error

  `:reason` is the message returned by the API, an exception raised by the HTTP
  client, or `{:http_error, status}` if the API replied with an unsuccessful
  status and an empty body. `:response` holds the raw HTTP response, or `nil`
  if the request never got that far.
  """

  alias Discovergy.HTTPClient

  @type response :: {HTTPClient.status(), HTTPClient.headers(), HTTPClient.body()}

  @type t :: %__MODULE__{reason: term(), response: response() | nil}

  defexception [:reason, :response]

  @impl true
  def message(%__MODULE__{reason: reason}) when is_binary(reason), do: reason
  def message(%__MODULE__{reason: {:http_error, status}}), do: "HTTP #{status}"

  def message(%__MODULE__{reason: %{__exception__: true} = reason}) do
    Exception.message(reason)
  end

  def message(%__MODULE__{reason: reason}) do
    inspect(reason)
  end
end
