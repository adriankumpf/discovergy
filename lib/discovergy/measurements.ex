defmodule Discovergy.Measurements do
  @moduledoc """
  The Measurements endpoint.
  """

  use Discovergy

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

  ## Examples

      iex> Discovergy.Measurements.readings(client, meter_id, from, to,
      ...>                                  resolution: :one_month)
      {:ok, [
       %{
         "time" => 1563314400000,
         "values" => %{
           "energy" => 8069238602135,
           "energy1" => 0,
           "energy2" => 0,
           "energyOut" => 2033461000,
           "energyOut1" => 0,
           "energyOut2" => 0,
           "power" => 512286,
           "power1" => 189978,
           "power2" => 129660,
           "power3" => 192654,
           "voltage1" => 230469,
           "voltage2" => 231599,
           "voltage3" => 230247
         }
       },
       ...
      ]}

  """
  @spec readings(Client.t(), Meter.id(), DateTime.t(), DateTime.t(), Keyword.t()) ::
          {:ok, [map()]} | {:error, Error.t()}
  def readings(%Client{} = client, meter_id, from, to \\ nil, opts \\ []) do
    parameters =
      [
        meterId: meter_id,
        from: DateTime.to_unix(from, :millisecond),
        to: to && DateTime.to_unix(to, :millisecond),
        fields: Enum.join(opts[:fields] || [], ","),
        resolution: opts[:resolution],
        disaggregation: opts[:disaggregation],
        each: opts[:each]
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    get(client, "/readings", query: parameters)
  end

  @doc """
  Return the last measurement for the specified meter.

  ## Options

    * `:fields` - list of measurement fields to return in the result (use
    `Discovergy.Metadata.field_names/2` to get all available fields)
    * `:each"` - Return data from the virtual meter itself (false) or all its
    sub-meters (true). Only applies if meterId refers to a virtual meter

  ## Examples

      iex> Discovergy.Measurements.last_reading(client, meter_id)
      {:ok, %{
        "time" => 1593904156020,
        "values" => %{
          "energy" => 441576730000,
          "energyOut" => 2154853000,
          "power" => 205980,
          "power1" => 63090,
          "power2" => 53780,
          "power3" => 89100,
          "voltage1" => 234100,
          "voltage2" => 234000,
          "voltage3" => 233800
        }
      }}

  """
  @spec last_reading(Client.t(), Meter.id(), Keyword.t()) :: {:ok, [map()]} | {:error, Error.t()}
  def last_reading(%Client{} = client, meter_id, opts \\ []) do
    parameters =
      [
        meterId: meter_id,
        fields: Enum.join(opts[:fields] || [], ","),
        each: opts[:each]
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    get(client, "/last_reading", query: parameters)
  end

  @doc """
  Return various statistics calculated over all measurements for the specified
  meter in the specified time interval.

  ## Options

    * `:fields` - list of measurement fields to return in the result (use
    `Discovergy.Metadata.field_names/2` to get all available fields)

  ## Examples

      iex> Discovergy.Measurements.statistics(client, meter_id, from)
      {:ok, %{
        "energy" => %{
          "count" => 53962,
          "maximum" => 441687910000,
          "mean" => 420770138841.7405,
          "minimum" => 402102161000,
          "variance" => 1.430940674699829e20
        },
        "energyOut" => %{
          ...
        },
        "power" => %{
          ...
        },
        "power1" => %{
          ...
        },
        "power2" => %{
          ...
        },
        "power3" => %{
          ...
        },
        "voltage1" => %{
          ...
        },
        "voltage2" => %{
          ...
        },
        "voltage3" => %{
          ...
        }
      }}
  """
  @spec statistics(Client.t(), Meter.id(), DateTime.t(), DateTime.t(), Keyword.t()) ::
          {:ok, map()} | {:error, Error.t()}
  def statistics(%Client{} = client, meter_id, from, to \\ nil, opts \\ []) do
    parameters =
      [
        meterId: meter_id,
        from: DateTime.to_unix(from, :millisecond),
        to: to && DateTime.to_unix(to, :millisecond),
        fields: Enum.join(opts[:fields] || [], ",")
      ]
      |> Enum.reject(fn {_, v} -> v in [nil, ""] end)

    get(client, "/statistics", query: parameters)
  end

  @doc """
  Return load profile for the given meter.

  ## Options

    * `:resolution` - reading resolution. Possible values: `:raw`, `:one_day`,
    `:one_month`, `:one_year`

  ## Examples

      iex> Discovergy.Measurements.load_profile(client, meter_id,
      ...>                                              ~D{2020-07-01},
      ...>                                              ~D{2020-07-01},
      ...>                                              resolution: :one_day)
      {:ok, [
        %{
          "1.29" => 0.816,
          "2.29" => 833.028,
          "3.29" => 179.376,
          "4.29" => 16.128,
          "5.29" => 9.06,
          "6.29" => 170.328,
          "7.29" => 12.744,
          "8.29" => 3.384,
          "status" => 0,
          "time" => 1593640800000
        },
        %{"1.6.0" => 0.96, "time" => 1593585000000},
        %{"2.6.0" => 142.44, "time" => 1593601200000}
      ]}

  """
  @spec load_profile(Client.t(), Meter.id(), Date.t(), Date.t(), Keyword.t()) ::
          {:ok, [map]} | {:error, Error.t()}
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
      |> Enum.reject(&match?({_, nil}, &1))

    get(client, "/load_profile", query: parameters)
  end

  @doc """
  Return the raw, unmodified load profile file as sent by the specified RLM
  meter on the specified date.

  ## Examples

      iex> {:ok, profile} =
      ...>   Discovergy.Measurements.raw_load_profile(client, meter_id, ~D{2020-07-01})
      {:ok, <<2, 80, 46, 48, 49, 40, 49, 50, 48, 48, 55, 48, 49, 48, 48, 49,
      53, 48, 48, 41, 40, 48, 48, 48, 48, 48, 48, 48, 48, 41, 40, 49, 53, 41,
      40, 56, 41, 40, 49, 46, 50, 57, 41, 40, 107, 87, 104, 41, ...>>}

      iex> String.split(profile)
      [
        <<2, 80, 46, 48, 49, 40, 49, 50, 48, 48, 55, 48, 49, 48, 48, 49, 53, 48, 48,
        41, 40, 48, 48, 48, 48, 48, 48, 48, 48, 41, 40, 49, 53, 41, 40, 56, 41, 40,
        49, 46, 50, 57, 41, 40, 107, 87, 104, 41, 40, ...>>,
        "(0.0001)(0.0000)(0.0000)(0.0032)(0.0000)(0.0000)(0.0026)(0.0007)",
        "(0.0000)(0.0000)(0.0000)(0.0035)(0.0000)(0.0000)(0.0029)(0.0005)",
        "(0.0000)(0.0001)(0.0000)(0.0036)(0.0000)(0.0000)(0.0030)(0.0006)",
        ...
      ]

  """
  @spec raw_load_profile(Client.t(), Meter.id(), Date.t()) ::
          {:ok, String.t()} | {:error, Error.t()}
  def raw_load_profile(%Client{} = client, meter_id, date) do
    {year, month, day} = Date.to_erl(date)

    parameters = [
      meterId: meter_id,
      year: year,
      month: month,
      day: day
    ]

    get(client, "/raw_load_profile", query: parameters)
  end
end
