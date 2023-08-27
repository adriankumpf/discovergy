defmodule Discovergy.Error do
  @moduledoc """
  A Discovergy Error
  """

  alias Discovergy.HTTPClient

  @type t :: %__MODULE__{
          reason: term(),
          response: {HTTPClient.status(), HTTPClient.headers(), HTTPClient.body()}
        }

  defexception [:reason, :response]

  @impl true
  def message(%__MODULE__{reason: reason}) when is_binary(reason), do: reason

  def message(%__MODULE__{reason: reason}) when is_exception(reason) do
    Exception.message(reason)
  end

  def message(%__MODULE__{reason: reason}) do
    inspect(reason)
  end
end
