defmodule Discovergy.Disaggregation do
  @moduledoc """
  """

  use Discovergy

  @typedoc """
  A UNIX millisecond timestamp
  """
  @type timestamp :: non_neg_integer()

  @doc """
  Provides the disaggregated energy for the specified meter at 15 minute
  intervals.
  """
  @spec disaggregation(Client.t(), String.t(), timestamp, timestamp | nil) ::
          {:ok, [map]} | {:error, Error.t()}
  def disaggregation(%Client{} = client, meter_id, from, to \\ nil) do
    parameters =
      [
        meterId: meter_id,
        from: from,
        to: to
      ]
      |> Enum.reject(&match?({_, nil}, &1))

    request(client, :get, "/disaggregation", [], query: parameters)
  end

  @doc """
  Returns the activities recognised for the given meter during the given
  interval.
  """
  @spec activities(Client.t(), String.t(), timestamp, timestamp) ::
          {:ok, [map]} | {:error, Error.t()}
  def activities(%Client{} = client, meter_id, from, to) do
    parameters =
      [
        meterId: meter_id,
        from: from,
        to: to
      ]
      |> Enum.reject(&match?({_, nil}, &1))

    request(client, :get, "/activities", [], query: parameters)
  end
end
