defmodule Discovergy.MixProject do
  use Mix.Project

  @version "0.7.0"
  @source_url "https://github.com/adriankumpf/discovergy"

  def project do
    [
      app: :discovergy,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "A simple wrapper for the Discovergy REST API",
      package: package(),
      docs: docs(),
      deps: deps(),
      xref: [exclude: [Finch]]
    ]
  end

  def application do
    [mod: {Discovergy.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:oauther, "~> 1.1"},
      {:jason, "~> 1.2"},
      {:finch, "~> 0.16", optional: true},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["Adrian Kumpf"],
      links: %{"GitHub" => @source_url, "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md"},
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      extras: ~w(CHANGELOG.md README.md),
      source_ref: "#{@version}",
      source_url: @source_url,
      main: "readme",
      groups_for_modules: [
        "HTTP Client": ~r/HTTPClient/,
        Endpoints: [
          Discovergy.Disaggregation,
          Discovergy.Measurements,
          Discovergy.Metadata,
          Discovergy.VirtualMeters,
          Discovergy.WebsiteAccessCode
        ],
        Models: [
          Discovergy.Measurement,
          Discovergy.Meter,
          Discovergy.Location,
          Discovergy.DisaggregationActivity,
          Discovergy.EnergyByDeviceMeasurement
        ]
      ],
      skip_undefined_reference_warnings_on: ~w(CHANGELOG.md README.md)
    ]
  end
end
