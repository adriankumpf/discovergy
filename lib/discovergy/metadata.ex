defmodule Discovergy.Metadata do
  use Discovergy

  @doc """
  Returns the devices recognised for the given meter.
  """
  @spec devices(Discovergy.Client.t(), String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def devices(%Discovergy.Client{} = client, meter_id) do
    with {:ok, %Tesla.Env{status: 200, body: devices}} <-
           request(client, :get, "/devices", [], query: [meterId: meter_id]) do
      {:ok, devices}
    end
  end

  defmodule Meter do
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
  @spec meters(Discovergy.Client.t()) :: {:ok, [Meter.t()]} | {:error, term()}
  def meters(%Discovergy.Client{} = client) do
    with {:ok, %Tesla.Env{status: 200, body: body}} <- request(client, :get, "/meters") do
      meters =
        Enum.map(body, fn attrs ->
          fields = Enum.map(attrs, &key_to_exising_atom/1)
          struct(Meter, fields)
        end)

      {:ok, meters}
    end
  end

  @doc """
  Return the available measurement field names for the specified meter.
  """
  @spec field_names(Discovergy.Client.t(), String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def field_names(%Discovergy.Client{} = client, meter_id) do
    with {:ok, %Tesla.Env{status: 200, body: field_names}} <-
           request(client, :get, "/field_names", [], query: [meterId: meter_id]) do
      {:ok, field_names}
    end
  end

  defp key_to_exising_atom({key, val}) do
    {String.to_existing_atom(key), val}
  rescue
    ArgumentError -> {key, val}
  end
end
