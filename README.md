# Discovergy

[Online Documentation](https://hexdocs.pm/discovergy).

<!-- MDOC !-->

`Discovergy` is a simple wrapper for the [Discovergy REST API](https://api.discovergy.com/docs/), providing access to meters and measurements.

## Examples

```elixir
iex> {:ok, client} = Discovergy.Client.new()
...>                 |> Discovergy.Client.login(email, password)
{:ok, %Discovergy.Client{}}

iex> Discovergy.Metadata.get_meters(client)
{:ok, [%Discovergy.Meter{
  administration_number: "",
  current_scaling_factor: 1,
  first_measurement_time: 1563286659367,
  full_serial_number: "1ESY1161229886",
  internal_meters: 1,
  last_measurement_time: 1593949473598,
  load_profile_type: "SLP",
  location: %Discovergy.Location{
  city: "Greven",
   country: "DE",
   street: "Sedanstr.",
   street_number: "8",
   zip: "48268"
  },
  manufacturer_id: "ESY",
  measurement_type: "ELECTRICITY",
  meter_id: "c1972a89ce3a4d58aadcb7908a1d31c7",
  scaling_factor: 1,
  serial_number: "61229886",
  type: "EASYMETER",
  voltage_scaling_factor: 1
}]}

```

<!-- MDOC !-->

## Installation

Add `discovergy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:discovergy, "~> 0.1.0"}
  ]
end
```

The docs can be found at https://hexdocs.pm/discovergy.
