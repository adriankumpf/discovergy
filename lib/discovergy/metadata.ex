defmodule Discovergy.Metadata do
  @moduledoc """
  """

  use Discovergy

  @doc """
  Returns the devices recognised for the given meter.
  """
  @spec devices(Client.t(), String.t()) :: {:ok, [String.t()]} | {:error, Error.t()}
  def devices(%Client{} = client, meter_id) do
    request(client, :get, "/devices", [], query: [meterId: meter_id])
  end

  defmodule Meter do
    @moduledoc false

    @type t() :: %__MODULE__{
            administrationNumber: String.t(),
            currentScalingFactor: integer(),
            firstMeasurementTime: integer(),
            fullSerialNumber: String.t(),
            internalMeters: integer(),
            lastMeasurementTime: integer(),
            loadProfileType: String.t(),
            location: map(),
            manufacturerId: String.t(),
            measurementType: String.t(),
            meterId: String.t(),
            scalingFactor: integer(),
            serialNumber: String.t(),
            type: String.t(),
            voltageScalingFactor: integer()
          }

    defstruct [
      :administrationNumber,
      :currentScalingFactor,
      :firstMeasurementTime,
      :fullSerialNumber,
      :internalMeters,
      :lastMeasurementTime,
      :loadProfileType,
      :location,
      :manufacturerId,
      :measurementType,
      :meterId,
      :scalingFactor,
      :serialNumber,
      :type,
      :voltageScalingFactor
    ]
  end

  @doc """
  Return all meters that the user has access to.
  """
  @spec meters(Client.t()) :: {:ok, [Meter.t()]} | {:error, Error.t()}
  def meters(%Client{} = client) do
    with {:ok, meters} <- request(client, :get, "/meters") do
      meters =
        Enum.map(meters, fn attrs ->
          fields = Enum.map(attrs, &key_to_exising_atom/1)
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
    request(client, :get, "/field_names", [], query: [meterId: meter_id])
  end

  defp key_to_exising_atom({key, val}) do
    {String.to_existing_atom(key), val}
  rescue
    ArgumentError -> {key, val}
  end
end
