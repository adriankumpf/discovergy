defmodule Discovergy.Model do
  @moduledoc false

  @callback into(Enumerable.t()) :: struct

  defmacro __using__(_opts) do
    quote do
      @behaviour Discovergy.Model

      @impl true
      def into(attrs) do
        fields = Enum.map(attrs, &camel_cased_key_to_exising_atom/1)
        struct(__MODULE__, fields)
      end

      defoverridable into: 1

      defp camel_cased_key_to_exising_atom({key, val}) do
        {key
         |> Macro.underscore()
         |> String.to_existing_atom(), val}
      rescue
        ArgumentError -> {key, val}
      end
    end
  end
end

defmodule Discovergy.Meter do
  use Discovergy.Model

  @type t :: %__MODULE__{
          administration_number: String.t(),
          current_scaling_factor: integer,
          first_measurement_time: non_neg_integer,
          full_serial_number: String.t(),
          internal_meters: non_neg_integer,
          last_measurement_time: non_neg_integer,
          load_profile_type: String.t(),
          location: Discovergy.Location.t(),
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

  @impl true
  def into(attrs) do
    fields =
      Enum.map(attrs, fn
        {"location", location} -> {:location, Discovergy.Location.into(location)}
        {key, value} -> camel_cased_key_to_exising_atom({key, value})
      end)

    struct(__MODULE__, fields)
  end
end

defmodule Discovergy.Location do
  use Discovergy.Model

  @type t :: %__MODULE__{
          city: String.t(),
          country: String.t(),
          street: String.t(),
          street_number: String.t(),
          zip: String.t()
        }

  defstruct [:city, :country, :street, :street_number, :zip]
end

defmodule Discovergy.Measurement do
  use Discovergy.Model

  @type t :: %__MODULE__{
          time: DateTime.t(),
          values: [map]
        }

  defstruct [:time, :values]

  @impl true
  def into(%{"time" => time, "values" => values}) do
    %__MODULE__{time: DateTime.from_unix!(time, :millisecond), values: values}
  end
end

defmodule Discovergy.DisaggregationActivity do
  use Discovergy.Model

  @type t :: %__MODULE__{
          activity_id: integer,
          begin_time: DateTime.t(),
          end_time: DateTime.t(),
          device_id: integer,
          device_name: String.t(),
          device_type: String.t(),
          energy: integer()
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

  @impl true
  def into(attrs) do
    fields =
      Enum.map(attrs, fn
        {"beginTime", time} -> {:begin_time, DateTime.from_unix!(time, :millisecond)}
        {"endTime", time} -> {:end_time, DateTime.from_unix!(time, :millisecond)}
        {key, value} -> camel_cased_key_to_exising_atom({key, value})
      end)

    struct(__MODULE__, fields)
  end
end

defmodule Discovergy.EnergyByDeviceMeasurement do
  use Discovergy.Model

  @type t :: %__MODULE__{
          time: DateTime.t(),
          energy_by_device: map
        }

  defstruct [:time, :energy_by_device]

  @impl true
  def into({time, energy_by_device}) do
    time = time |> String.to_integer() |> DateTime.from_unix!(:millisecond)
    %__MODULE__{time: time, energy_by_device: energy_by_device}
  end
end
