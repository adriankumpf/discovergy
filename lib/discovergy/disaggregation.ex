defmodule Discovergy.Disaggregation do
  @moduledoc """
  The Disaggregation endpoint.
  """

  use Discovergy

  @doc """
  Provides the disaggregated energy for the specified meter at 15 minute
  intervals.
  """
  @spec disaggregation(Client.t(), Meter.id(), DateTime.t(), DateTime.t()) ::
          {:ok, [map]} | {:error, Error.t()}
  def disaggregation(%Client{} = client, meter_id, from, to \\ nil) do
    parameters =
      [
        meterId: meter_id,
        from: DateTime.to_unix(from, :millisecond),
        to: to && DateTime.to_unix(to, :millisecond)
      ]
      |> Enum.reject(&match?({_, nil}, &1))

    get(client, "/disaggregation", query: parameters)
  end

  @doc """
    Returns the activities recognised for the given meter during the given
    interval.

    ## Examples

        iex> {from, to} = {~U[2019-10-31 19:59:03Z], DateTime.utc_now()}
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
  @spec activities(Client.t(), Meter.id(), DateTime.t(), DateTime.t()) ::
          {:ok, [map]} | {:error, Error.t()}
  def activities(%Client{} = client, meter_id, from, to) do
    parameters =
      [
        meterId: meter_id,
        from: DateTime.to_unix(from, :millisecond),
        to: DateTime.to_unix(to, :millisecond)
      ]

    get(client, "/activities", query: parameters)
  end
end
