defmodule Discovergy.BasicAuth do
  @moduledoc false

  @type t :: %__MODULE__{email: String.t(), password: String.t()}

  @derive {Inspect, except: [:password]}
  @enforce_keys [:email, :password]
  defstruct [:email, :password]

  @spec authorization(t) :: {String.t(), String.t()}
  def authorization(%__MODULE__{email: email, password: password}) do
    {"authorization", "Basic " <> Base.encode64("#{email}:#{password}")}
  end
end
