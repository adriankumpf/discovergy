# Discovergy

[Online Documentation](https://hexdocs.pm/discovergy).

<!-- MDOC !-->

`Discovergy` is a simple wrapper for the [Discovergy REST API](https://api.discovergy.com/docs/), providing access to meters and measurements.

## Examples

```elixir
iex> {:ok, client} = Discovergy.Client.new()
...>                 |> Discovergy.Client.login(email, password)
{:ok, %Discovergy.Client{}}

iex> Discovergy.Metadata.meters(client)
{:ok, [%Discovergy.Metadata.Meter{
  administrationNumber: "DE0000000000000000000000000000000",
  currentScalingFactor: 1,
  firstMeasurementTime: 1593580000000,
  fullSerialNumber: "1A2B3C4D5E6F7G",
  internalMeters: 1,
  lastMeasurementTime: 1593901000000,
  loadProfileType: "SLP",
  location: %{"city" => "Berlin", "country" => "DE"},
  manufacturerId: "ESY",
  measurementType: "ELECTRICITY",
  meterId: "a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1",
  scalingFactor: 1,
  serialNumber: "12345678",
  type: "EASYMETER",
  voltageScalingFactor: 1
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
