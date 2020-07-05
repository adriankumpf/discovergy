defmodule Discovergy.Metadata do
  @moduledoc """
  The Metadata endpoint.
  """

  use Discovergy

  @doc """
  Returns the devices recognised for the given meter.
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
  end

  @doc """
  Return all meters that the user has access to.
  """
  @spec meters(Client.t()) :: {:ok, [Meter.t()]} | {:error, Error.t()}
  def meters(%Client{} = client) do
    with {:ok, meters} <- get(client, "/meters") do
      meters =
        Enum.map(meters, fn attrs ->
          fields = Enum.map(attrs, &camel_cased_key_to_exising_atom/1)
          struct(Meter, fields)
        end)

      {:ok, meters}
    end
  end

  @doc """
  Return the available measurement field names for the specified meter.
  """
  @spec field_names(Client.t(), String.t()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def field_names(%Client{} = client, meter_id) do
    get(client, "/field_names", query: [meterId: meter_id])
  end

  defp camel_cased_key_to_exising_atom({key, val}) do
    {key
     |> Macro.underscore()
     |> String.to_existing_atom(), val}
  rescue
    ArgumentError -> {key, val}
  end
end
