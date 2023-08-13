defmodule Discovergy.VirtualMeters do
  @moduledoc """
  The Virtual Meters endpoint
  """

  alias Discovergy.Client

  @doc """
  Return the individual meters comprising the specified virtual meter.
  """
  @spec get_virtual_meter(Client.t(), Meter.id()) :: {:ok, [Meter.t()]} | {:error, Error.t()}
  def get_virtual_meter(%Client{} = client, meter_id) do
    with {:ok, meters} <- Client.get(client, "/virtual_meter", query: [meterId: meter_id]) do
      {:ok, Enum.map(meters, &Discovergy.Meter.into/1)}
    end
  end

  @doc """
  Return the individual meters comprising the specified virtual meter.
  """
  @spec create_virtual_meter(Client.t(), [Meter.id()], [Meter.id()]) ::
          {:ok, map} | {:error, Error.t()}
  def create_virtual_meter(%Client{} = client, meter_ids_plus, meter_ids_minus \\ []) do
    parameters =
      [
        meterIdsPlus: Enum.join(meter_ids_plus, ","),
        meterIdsMinus: Enum.join(meter_ids_minus, ",")
      ]
      |> Enum.reject(&match?("", &1))

    Client.get(client, "/virtual_meter", query: parameters)
  end
end
