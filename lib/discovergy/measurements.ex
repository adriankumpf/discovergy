defmodule Discovergy.Measurements do
  use Discovergy

  alias Discovergy.Client

  @typedoc """
  A UNIX millisecond timestamp
  """
  @type timestamp :: non_neg_integer()

  @doc """
  Return the measurements for the specified meter in the specified time interval.

  ## Options

    * `:fields` - list of measurement fields to return in the result (use
    `Discovergy.Metadata.field_names/2` to get all available fields)
    * `:resolution` - time distance between returned readings. Possible values:
    `:raw` (default), `:three_minutes`, `:fifteen_minutes`, `:one_hour`, `:one_day`,
    `:one_week`, `:one_month`, `:one_year`
    * `: disaggregation ` - Include load disaggregation as pseudo-measurement
    fields, if available. Only applies if raw resolution is selected
    * `:each"` - Return data from the virtual meter itself (false) or all its
    sub-meters (true). Only applies if meterId refers to a virtual meter

  """
  @spec readings(Client.t(), String.t(), timestamp(), timestamp() | nil, Keyword.t()) ::
          {:ok, [map()]} | {:error, term()}
  def readings(%Client{} = client, meter_id, from, to \\ nil, opts \\ []) do
    parameters =
      [
        meterId: meter_id,
        from: from,
        to: to,
        fields: Enum.join(opts[:fields] || [], ","),
        resolution: opts[:resolution],
        disaggregation: opts[:disaggregation],
        each: opts[:each]
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    with {:ok, %Tesla.Env{status: 200, body: measurements}} <-
           request(client, :get, "/readings", [], query: parameters) do
      {:ok, measurements}
    end
  end

  @doc """
  Return the last measurement for the specified meter.

  ## Options

    * `:fields` - list of measurement fields to return in the result (use
    `Discovergy.Metadata.field_names/2` to get all available fields)
    * `:each"` - Return data from the virtual meter itself (false) or all its
    sub-meters (true). Only applies if meterId refers to a virtual meter

  """
  @spec last_reading(Client.t(), String.t(), Keyword.t()) :: {:ok, [map()]} | {:error, term()}
  def last_reading(%Client{} = client, meter_id, opts \\ []) do
    parameters =
      [
        meterId: meter_id,
        fields: Enum.join(opts[:fields] || [], ","),
        each: opts[:each]
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    with {:ok, %Tesla.Env{status: 200, body: measurement}} <-
           request(client, :get, "/last_reading", [], query: parameters) do
      {:ok, measurement}
    end
  end

  @doc """
  Return various statistics calculated over all measurements for the specified
  meter in the specified time interval.

  ## Options

    * `:fields` - list of measurement fields to return in the result (use
    `Discovergy.Metadata.field_names/2` to get all available fields)

  """
  @spec statistics(Client.t(), String.t(), timestamp(), timestamp() | nil, Keyword.t()) ::
          {:ok, map()} | {:error, term()}
  def statistics(%Client{} = client, meter_id, from, to \\ nil, opts \\ []) do
    parameters =
      [
        meterId: meter_id,
        from: from,
        to: to,
        fields: Enum.join(opts[:fields] || [], ",")
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    with {:ok, %Tesla.Env{status: 200, body: statistics}} <-
           request(client, :get, "/statistics", [], query: parameters) do
      {:ok, statistics}
    end
  end

  @doc """
  Return load profile for the given meter.

  ## Options

    * `:resolution` - reading resolution. Possible values: `:raw`, `:one_day`,
    `:one_month`, `:one_year`

  """
  @spec load_profile(Client.t(), String.t(), Date.t(), Date.t(), Keyword.t()) ::
          {:ok, [map()]} | {:error, term()}
  def load_profile(%Client{} = client, meter_id, from, to, opts \\ []) do
    {from_year, from_month, from_day} = Date.to_erl(from)
    {to_year, to_month, to_day} = Date.to_erl(to)

    parameters =
      [
        meterId: meter_id,
        fromYear: from_year,
        fromMonth: from_month,
        fromDay: from_day,
        toYear: to_year,
        toMonth: to_month,
        toDay: to_day,
        resolution: opts[:resolution]
      ]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    with {:ok, %Tesla.Env{status: 200, body: load_profile}} <-
           request(client, :get, "/load_profile", [], query: parameters) do
      {:ok, load_profile}
    end
  end

  @doc """
  Return the raw, unmodified load profile file as sent by the specified RLM
  meter on the specified date.
  """
  @spec raw_load_profile(Client.t(), String.t(), Date.t()) :: {:ok, String.t()} | {:error, term()}
  def raw_load_profile(%Client{} = client, meter_id, date) do
    {year, month, day} = Date.to_erl(date)

    parameters = [
      meterId: meter_id,
      year: year,
      month: month,
      day: day
    ]

    with {:ok, %Tesla.Env{status: 200, body: load_profile}} <-
           request(client, :get, "/raw_load_profile", [], query: parameters) do
      {:ok, load_profile}
    end
  end
end
