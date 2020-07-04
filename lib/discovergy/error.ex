defmodule Discovergy.Error do
  @moduledoc """
  A Discovergy Error.
  """

  @type t :: %__MODULE__{
          reason: atom() | String.t(),
          env: Tesla.Env.t()
        }

  defexception [:reason, :env]

  @impl true
  def message(%__MODULE__{reason: reason}) do
    reason
  end
end
