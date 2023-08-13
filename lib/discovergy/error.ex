defmodule Discovergy.Error do
  @moduledoc """
  A Discovergy Error
  """

  alias Discovergy.HTTPClient

  @type t :: %__MODULE__{
          reason: atom() | String.t(),
          response: {HTTPClient.status(), HTTPClient.headers(), HTTPClient.body()}
        }

  defexception [:reason, :response]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    to_string(reason)
  end
end
