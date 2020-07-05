defmodule Discovergy.Metadata do
  @moduledoc """
  The Metadata endpoint.
  """

  use Discovergy

  @doc """
  Returns the devices recognised for the given meter.

  ## Examples

      iex> Discovergy.Metadata.devices(client, "4fbcd2ea7c8b45c0a3dd2ac01ca1ccec")
      {:ok, ["BASE_LOAD-1", "DISHWASHER-1", "ELECTRIC_VEHICLE-1", "OVEN-1", "OVEN-2",
      "REFRIGERATOR-1", "REFRIGERATOR-2", "REFRIGERATOR-3", "WASHING_MACHINE-1",
      "WATER_HEATER-1", "WATER_HEATER-2", "WATER_HEATER-3"]}

  """
  @spec devices(Client.t(), Meter.id()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def devices(%Client{} = client, meter_id) do
    get(client, "/devices", query: [meterId: meter_id])
  end

  defmodule Meter do
    @moduledoc false

    @type t :: %__MODULE__{
            administration_number: String.t(),
            current_scaling_factor: integer,
            first_measurement_time: non_neg_integer,
            full_serial_number: String.t(),
            internal_meters: non_neg_integer,
            last_measurement_time: non_neg_integer,
            load_profile_type: String.t(),
            location: map,
            manufacturer_id: String.t(),
            measurement_type: String.t(),
            meter_id: String.t(),
            scaling_factor: integer(),
            serial_number: String.t(),
            type: String.t(),
            voltage_scaling_factor: integer
          }

    @type id :: String.t()

    defstruct [
      :administration_number,
      :current_scaling_factor,
      :first_measurement_time,
      :full_serial_number,
      :internal_meters,
      :last_measurement_time,
      :load_profile_type,
      :location,
      :manufacturer_id,
      :measurement_type,
      :meter_id,
      :scaling_factor,
      :serial_number,
      :type,
      :voltage_scaling_factor
    ]

    @doc false
    @spec into(Enumerable.t()) :: t
    def into(attrs) do
      fields = Enum.map(attrs, &camel_cased_key_to_exising_atom/1)
      struct(__MODULE__, fields)
    end

    defp camel_cased_key_to_exising_atom({key, val}) do
      {key
       |> Macro.underscore()
       |> String.to_existing_atom(), val}
    rescue
      ArgumentError -> {key, val}
    end
  end

  @doc """
  Return all meters that the user has access to.

  ## Examples

      iex> {:ok, meters} = Discovergy.Metadata.meters(client)
      {:ok, [%Discovergy.Metadata.Meter{
         meter_id: "c1972a89ce3a4d58aadcb7908a1d31c7",
         serial_number: "61229886",
         full_serial_number: "1ESY1161229886",
         location: %{
           "city" => "Greven",
           "country" => "DE",
           "street" => "Sedanstr.",
           "streetNumber" => "8",
           "zip" => "48268"
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
  @spec meters(Client.t()) :: {:ok, [Meter.t()]} | {:error, Error.t()}
  def meters(%Client{} = client) do
    with {:ok, meters} <- get(client, "/meters") do
      {:ok, Enum.map(meters, &Meter.into/1)}
    end
  end

  @doc """
  Return the available measurement field names for the specified meter.

  ## Examples

      iex> Discovergy.Metadata.field_names(client, "4fbcd2ea7c8b45c0a3dd2ac01ca1ccec")
      {:ok, ["energy", "energy1", "energy2", "energyOut", "energyOut1", "energyOut2",
      "power", "power1", "power2", "power3", "voltage1", "voltage2", "voltage3"]}

  """
  @spec field_names(Client.t(), Meter.id()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def field_names(%Client{} = client, meter_id) do
    get(client, "/field_names", query: [meterId: meter_id])
  end
end
