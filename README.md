# Discovergy

[![Build Status](https://github.com/adriankumpf/discovergy/workflows/CI/badge.svg)](https://github.com/adriankumpf/discovergy/actions)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/discovergy)
[![Hex.pm](https://img.shields.io/hexpm/v/discovergy?color=%23714a94)](http://hex.pm/packages/discovergy)

> A client for the [Discovergy REST API](https://api.discovergy.com/docs/), providing access to meters and measurements.

## Installation

Add `:discovergy` and `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:discovergy, "~> 0.6"},
    {:finch, "~> 0.16"}
  ]
end
```

## Usage

Create a `Discovergy.Client` and authenticate with the Discovergy API using your email address and password.

```elixir
iex> {:ok, client} = Discovergy.Client.new() |> Discovergy.Client.login(email, password)
{:ok, %Discovergy.Client{}}
```

Then pass the `client` to the respective endpoint function. For example, to list all meters the user has access to:

```elixir
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

Or to obtain the last measurement of a particular meter:

```elixir
iex> Discovergy.Measurements.get_last_reading(client, "c1972a89ce3a4d58aadcb7908a1d31c7")
{:ok, %Discovergy.Measurement{
  time: ~U[2019-07-16 22:00:00.000Z],
  values: %{
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
```

## License

This project is Licensed under the [MIT License](LICENSE).
