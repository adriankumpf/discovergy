defmodule Discovergy.Location do
  @moduledoc """
  The address a meter is installed at.
  """

  alias Discovergy.Model

  @type t :: %__MODULE__{
          city: String.t(),
          country: String.t(),
          street: String.t(),
          street_number: String.t(),
          zip: String.t()
        }

  defstruct [:city, :country, :street, :street_number, :zip]

  @doc false
  def into(attrs), do: Model.cast(__MODULE__, attrs)
end

defmodule Discovergy.Meter do
  @moduledoc """
  A meter the user has access to.
  """

  alias Discovergy.{Location, Model}

  @type t :: %__MODULE__{
          administration_number: String.t(),
          current_scaling_factor: integer,
          first_measurement_time: non_neg_integer,
          full_serial_number: String.t(),
          internal_meters: non_neg_integer,
          kwh_scaling_factor: integer,
          last_measurement_time: non_neg_integer,
          load_profile_type: String.t(),
          location: Location.t(),
          manufacturer_id: String.t(),
          measurement_type: String.t(),
          meter_id: id,
          printed_full_serial_number: String.t(),
          scaling_factor: integer,
          serial_number: String.t(),
          storage_numbers: [integer],
          submeter: boolean,
          type: String.t(),
          voltage_scaling_factor: integer
        }

  @typedoc "The identifier of a meter."
  @type id :: String.t()

  defstruct [
    :administration_number,
    :current_scaling_factor,
    :first_measurement_time,
    :full_serial_number,
    :internal_meters,
    :kwh_scaling_factor,
    :last_measurement_time,
    :load_profile_type,
    :location,
    :manufacturer_id,
    :measurement_type,
    :meter_id,
    :printed_full_serial_number,
    :scaling_factor,
    :serial_number,
    :storage_numbers,
    :submeter,
    :type,
    :voltage_scaling_factor
  ]

  @doc false
  def into(attrs) do
    Model.cast(__MODULE__, attrs,
      cast: %{"location" => &Location.into/1},
      # Macro.underscore/1 would turn this key into "k_wh_scaling_factor"
      rename: %{"kWhScalingFactor" => :kwh_scaling_factor}
    )
  end
end

defmodule Discovergy.Measurement do
  @moduledoc """
  The values a meter reported at a point in time.
  """

  @type t :: %__MODULE__{time: DateTime.t(), values: %{String.t() => number}}

  defstruct [:time, :values]

  @doc false
  def into(%{"time" => time, "values" => values}) do
    %__MODULE__{time: DateTime.from_unix!(time, :millisecond), values: values}
  end
end

defmodule Discovergy.DisaggregationActivity do
  @moduledoc """
  A period during which a disaggregated device was recognised as active.
  """

  alias Discovergy.Model

  @type t :: %__MODULE__{
          activity_id: integer,
          begin_time: DateTime.t(),
          end_time: DateTime.t(),
          device_id: integer,
          device_name: String.t(),
          device_type: String.t(),
          energy: integer
        }

  defstruct [
    :activity_id,
    :begin_time,
    :end_time,
    :device_id,
    :device_name,
    :device_type,
    :energy
  ]

  @doc false
  def into(attrs) do
    to_datetime = &DateTime.from_unix!(&1, :millisecond)

    Model.cast(__MODULE__, attrs, cast: %{"beginTime" => to_datetime, "endTime" => to_datetime})
  end
end

defmodule Discovergy.EnergyByDeviceMeasurement do
  @moduledoc """
  The energy consumed per disaggregated device during a 15 minute interval.
  """

  @type t :: %__MODULE__{time: DateTime.t(), energy_by_device: %{String.t() => number}}

  defstruct [:time, :energy_by_device]

  @doc false
  def into({time, energy_by_device}) do
    %__MODULE__{
      time: time |> String.to_integer() |> DateTime.from_unix!(:millisecond),
      energy_by_device: energy_by_device
    }
  end
end
