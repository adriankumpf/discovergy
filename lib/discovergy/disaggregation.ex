defmodule Discovergy.Disaggregation do
  @moduledoc """
  The Disaggregation endpoint.
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

    get(client, "/disaggregation", query: parameters)
  end

  @doc """
    Returns the activities recognised for the given meter during the given
    interval.

    ## Examples

        iex> from = DateTime.utc_now()
        ...>        |> DateTime.add(-15*60*60)
        ...>        |> DateTime.to_unix(:millisecond)
        iex> to = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
        iex> Discovergy.Measurements.activities(client, meter_id, from, to)
        {:ok, [
          %{
           "activityId" => 2575680,
           "beginTime" => 1593427980000,
           "deviceId" => 3,
           "deviceName" => "REFRIGERATOR-3",
           "deviceType" => "REFRIGERATOR",
           "endTime" => 1593428634000,
           "energy" => 666583333
          },
          ...
        ]}
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

    get(client, "/activities", query: parameters)
  end
end
