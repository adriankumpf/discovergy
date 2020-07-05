defmodule Discovergy.Metadata do
  @moduledoc """
  The Metadata endpoint
  """

  use Discovergy

  @doc """
  Returns the devices recognised for the given meter.

  ## Examples

      iex> Discovergy.Metadata.get_devices(client, meter_id)
      {:ok, ["BASE_LOAD-1", "DISHWASHER-1", "ELECTRIC_VEHICLE-1", "OVEN-1", "OVEN-2",
      "REFRIGERATOR-1", "REFRIGERATOR-2", "REFRIGERATOR-3", "WASHING_MACHINE-1",
      "WATER_HEATER-1", "WATER_HEATER-2", "WATER_HEATER-3"]}

  """
  @spec get_devices(Client.t(), Meter.id()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def get_devices(%Client{} = client, meter_id) do
    get(client, "/devices", query: [meterId: meter_id])
  end

  @doc """
  Return all meters that the user has access to.

  ## Examples

      iex> {:ok, meters} = Discovergy.Metadata.get_meters(client)
      {:ok, [%Discovergy.Meter{
         meter_id: "c1972a89ce3a4d58aadcb7908a1d31c7",
         serial_number: "61229886",
         full_serial_number: "1ESY1161229886",
         location: %Discovergy.Location{
           city: "Greven",
           country: "DE",
           street: "Sedanstr.",
           street_number: "8",
           zip: "48268"
         },
         administration_number: "",
         type: "EASYMETER",
         manufacturer_id: "ESY",
         measurement_type: "ELECTRICITY",
         scaling_factor: 1,
         current_scaling_factor: 1,
         voltage_scaling_factor: 1,
         internal_meters: 1,
         first_measurement_time: 1563286659367,
         last_measurement_time: 1593952103706,
         load_profile_type: "SLP"
      }]}

  """
  @spec get_meters(Client.t()) :: {:ok, [Meter.t()]} | {:error, Error.t()}
  def get_meters(%Client{} = client) do
    with {:ok, meters} <- get(client, "/meters") do
      {:ok, Enum.map(meters, &Meter.into/1)}
    end
  end

  @doc """
  Return the available measurement field names for the specified meter.

  ## Examples

      iex> Discovergy.Metadata.get_field_names(client, meter_id)
      {:ok, ["energy", "energy1", "energy2", "energyOut", "energyOut1", "energyOut2",
      "power", "power1", "power2", "power3", "voltage1", "voltage2", "voltage3"]}

  """
  @spec get_field_names(Client.t(), Meter.id()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def get_field_names(%Client{} = client, meter_id) do
    get(client, "/field_names", query: [meterId: meter_id])
  end
end
