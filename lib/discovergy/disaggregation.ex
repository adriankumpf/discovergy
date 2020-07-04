defmodule Discovergy.Disaggregation do
  use Discovergy

  alias Discovergy.Client

  @typedoc """
  A UNIX millisecond timestamp
  """
  @type timestamp :: non_neg_integer()

  @doc """
  Provides the disaggregated energy for the specified meter at 15 minute
  intervals.
  """
  @spec disaggregation(Client.t(), String.t(), timestamp(), timestamp() | nil) ::
          {:ok, [map()]} | {:error, term()}
  def disaggregation(%Client{} = client, meter_id, from, to \\ nil) do
    parameters =
      [
        meterId: meter_id,
        from: from,
        to: to
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    with {:ok, %Tesla.Env{status: 200, body: measurements}} <-
           request(client, :get, "/disaggregation", [], query: parameters) do
      {:ok, measurements}
    end
  end

  @doc """
  Returns the activities recognised for the given meter during the given
  interval.
  """
  @spec activities(Client.t(), String.t(), timestamp(), timestamp()) ::
          {:ok, [map()]} | {:error, term()}
  def activities(%Client{} = client, meter_id, from, to) do
    parameters =
      [
        meterId: meter_id,
        from: from,
        to: to
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    with {:ok, %Tesla.Env{status: 200, body: measurements}} <-
           request(client, :get, "/activities", [], query: parameters) do
      {:ok, measurements}
    end
  end
end
