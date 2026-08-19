defmodule Discovergy.VirtualMeters do
  @moduledoc """
  The Virtual Meters endpoint
  """

  alias Discovergy.Client
  alias Discovergy.Meter

  @doc """
  Return the individual meters comprising the specified virtual meter.

  ## Examples

      iex> Discovergy.VirtualMeters.get_virtual_meter(client, meter_id)
      {:ok, [%Discovergy.Meter{}, %Discovergy.Meter{}]}

  """
  @spec get_virtual_meter(Client.t(), Meter.id()) :: {:ok, [Meter.t()]} | {:error, Error.t()}
  def get_virtual_meter(%Client{} = client, meter_id) do
    with {:ok, meters} <- Client.get(client, "/virtual_meter", query: [meterId: meter_id]) do
      {:ok, Enum.map(meters, &Meter.into/1)}
    end
  end

  @doc """
  Create a virtual meter (meter group) from the given meters.

  The readings of the meters in `meter_ids_plus` are added up, those in
  `meter_ids_minus` are subtracted.

  ## Examples

      iex> Discovergy.VirtualMeters.create_virtual_meter(client, [meter_id, other_meter_id])
      {:ok, %Discovergy.Meter{}}

  """
  @spec create_virtual_meter(Client.t(), [Meter.id()], [Meter.id()]) ::
          {:ok, Meter.t()} | {:error, Error.t()}
  def create_virtual_meter(%Client{} = client, [_ | _] = meter_ids_plus, meter_ids_minus \\ []) do
    parameters = [
      meterIdsPlus: Enum.join(meter_ids_plus, ","),
      meterIdsMinus: join(meter_ids_minus)
    ]

    with {:ok, meter} <- Client.post(client, "/virtual_meter", [], query: parameters) do
      {:ok, Meter.into(meter)}
    end
  end

  defp join([]), do: nil
  defp join(meter_ids), do: Enum.join(meter_ids, ",")
end
