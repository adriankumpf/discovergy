defmodule Discovergy.Disaggregation do
  @moduledoc """
  The Disaggregation endpoint
  """

  alias Discovergy.Client
  alias Discovergy.{DisaggregationActivity, EnergyByDeviceMeasurement}

  @doc """
  Provides the disaggregated energy for the specified meter at 15 minute
  intervals.

  ## Examples

      iex> Discovergy.Disaggregation.get_energy_by_device_measurements(
      ...>  client, meter_id, from
      ...> )
      {:ok, [
        %Discovergy.EnergyByDeviceMeasurement{
          time: ~U[2020-07-01 22:15:00.000Z],
          energy_by_device: %{
            "Backofen-1" => 0,
            "Backofen-2" => 0,
            "Durchlauferhitzer-1" => 0,
            "Durchlauferhitzer-2" => 0,
            "Durchlauferhitzer-3" => 0,
            "Elektromobilität-1" => 0,
            "Grundlast-1" => 232500000,
            "Kühlschrank-1" => 1433333,
            "Kühlschrank-2" => 0,
            "Kühlschrank-3" => 0,
            "Spülmaschine-1" => 0,
            "Waschmaschine-1" => 0
          }
        },
        ...
      ]}

  """
  @spec get_energy_by_device_measurements(Client.t(), Meter.id(), DateTime.t(), DateTime.t()) ::
          {:ok, [EnergyByDeviceMeasurement.t()]} | {:error, Error.t()}
  def get_energy_by_device_measurements(%Client{} = client, meter_id, from, to \\ nil) do
    parameters =
      [
        meterId: meter_id,
        from: DateTime.to_unix(from, :millisecond),
        to: to && DateTime.to_unix(to, :millisecond)
      ]
      |> Enum.reject(&match?({_, nil}, &1))

    with {:ok, disaggregation} <- Client.get(client, "/disaggregation", query: parameters) do
      measurements =
        disaggregation
        |> Enum.map(&EnergyByDeviceMeasurement.into/1)
        |> Enum.sort_by(& &1.time, Date)

      {:ok, measurements}
    end
  end

  @doc """
  Returns the activities recognised for the given meter during the given
  interval.

  ## Examples

      iex> Discovergy.Measurements.get_activities(client, meter_id, from, to)
      {:ok, [
        %Discovergy.DisaggregationActivity{
          activity_id: 77,
          begin_time: ~U[2019-07-16 02:13:24.000Z],
          end_time: ~U[2019-07-16 22:00:00.000Z],
          device_id: 1,
          device_name: "BASE_LOAD-1",
          device_type: "BASE_LOAD",
          energy: 16414633333
        },
        ...
      ]}

  """
  @spec get_activities(Client.t(), Meter.id(), DateTime.t(), DateTime.t()) ::
          {:ok, [DisaggregationActivity.t()]} | {:error, Error.t()}
  def get_activities(%Client{} = client, meter_id, from, to) do
    parameters = [
      meterId: meter_id,
      from: DateTime.to_unix(from, :millisecond),
      to: DateTime.to_unix(to, :millisecond)
    ]

    with {:ok, activities} <- Client.get(client, "/activities", query: parameters) do
      {:ok, Enum.map(activities, &DisaggregationActivity.into/1)}
    end
  end
end
