defmodule Discovergy.Disaggregation do
  @moduledoc """
  The Disaggregation endpoint.
  """

  use Discovergy

  @doc """
  Provides the disaggregated energy for the specified meter at 15 minute
  intervals.

  ## Examples

      iex> Discovergy.Disaggregation.disaggregation(client, meter_id, from)
      {:ok, %{
        "1593887400000" => %{
          "Backofen-1" => 0,
          "Backofen-2" => 0,
          "Durchlauferhitzer-1" => 0,
          "Durchlauferhitzer-2" => 0,
          "Durchlauferhitzer-3" => 0,
          "Elektromobilität-1" => 0,
          "Grundlast-1" => 240000000,
          "Kühlschrank-1" => 0,
          "Kühlschrank-2" => 0,
          "Kühlschrank-3" => 0,
          "Spülmaschine-1" => 0,
          "Waschmaschine-1" => 0
        },
        ...
      }}

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
    parameters = [
      meterId: meter_id,
      from: DateTime.to_unix(from, :millisecond),
      to: DateTime.to_unix(to, :millisecond)
    ]

    get(client, "/activities", query: parameters)
  end
end
