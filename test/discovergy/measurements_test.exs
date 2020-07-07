defmodule Discovergy.MeasurementsTest do
  use Discovergy.Case, logged_in: true, async: true

  test "gets readings", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.discovergy.com/public/v1/readings",
        query: [
          meterId: "$meter_id",
          from: 1_593_561_600_000,
          to: 1_593_562_200_000
        ]
      } ->
        measurements = [
          %{
            "time" => 1_593_561_600_928,
            "values" => %{
              "energy" => 59_852_528_585_000,
              "energy1" => 0,
              "energy2" => 0,
              "energyOut" => 2_033_461_000,
              "energyOut1" => 0,
              "energyOut2" => 0,
              "power" => 147_460,
              "power1" => 101_620,
              "power2" => 6230,
              "power3" => 39610,
              "voltage1" => 230_700,
              "voltage2" => 230_400,
              "voltage3" => 230_300
            }
          },
          %{
            "time" => 1_593_561_601_928,
            "values" => %{
              "energy" => 59_852_528_991_000,
              "energy1" => 0,
              "energy2" => 0,
              "energyOut" => 2_033_461_000,
              "energyOut1" => 0,
              "energyOut2" => 0,
              "power" => 146_030,
              "power1" => 101_180,
              "power2" => 6200,
              "power3" => 38650,
              "voltage1" => 230_800,
              "voltage2" => 230_400,
              "voltage3" => 230_300
            }
          }
        ]

        json(measurements)
    end)

    assert {:ok,
            [
              %Discovergy.Measurement{
                time: ~U[2020-07-01 00:00:00.928Z],
                values: %{
                  "energy" => 59_852_528_585_000,
                  "energy1" => 0,
                  "energy2" => 0,
                  "energyOut" => 2_033_461_000,
                  "energyOut1" => 0,
                  "energyOut2" => 0,
                  "power" => 147_460,
                  "power1" => 101_620,
                  "power2" => 6230,
                  "power3" => 39610,
                  "voltage1" => 230_700,
                  "voltage2" => 230_400,
                  "voltage3" => 230_300
                }
              },
              %Discovergy.Measurement{
                time: ~U[2020-07-01 00:00:01.928Z],
                values: %{
                  "energy" => 59_852_528_991_000,
                  "energy1" => 0,
                  "energy2" => 0,
                  "energyOut" => 2_033_461_000,
                  "energyOut1" => 0,
                  "energyOut2" => 0,
                  "power" => 146_030,
                  "power1" => 101_180,
                  "power2" => 6200,
                  "power3" => 38650,
                  "voltage1" => 230_800,
                  "voltage2" => 230_400,
                  "voltage3" => 230_300
                }
              }
            ]} ==
             Discovergy.Measurements.get_readings(
               client,
               "$meter_id",
               ~U[2020-07-01 00:00:00Z],
               ~U[2020-07-01 00:10:00Z]
             )
  end

  test "gets last reading", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.discovergy.com/public/v1/last_reading",
        query: [meterId: "$meter_id", fields: "energy,power"]
      } ->
        measurement = %{
          "time" => 1_593_561_600_928,
          "values" => %{
            "energy" => 59_852_528_585_000,
            "power" => 147_460
          }
        }

        json(measurement)
    end)

    assert {:ok,
            %Discovergy.Measurement{
              time: ~U[2020-07-01 00:00:00.928Z],
              values: %{"energy" => 59_852_528_585_000, "power" => 147_460}
            }} ==
             Discovergy.Measurements.get_last_reading(client, "$meter_id",
               fields: [:energy, :power]
             )
  end

  test "gets statistics", %{client: client} do
    statistics = %{
      "voltage1" => %{
        "count" => 600,
        "maximum" => 231_500,
        "mean" => 230_935.6667,
        "minimum" => 230_400,
        "variance" => 60227.88888887056
      },
      "voltage2" => %{
        "count" => 600,
        "maximum" => 230_800,
        "mean" => 230_412.8333,
        "minimum" => 229_900,
        "variance" => 29885.30555556001
      },
      "voltage3" => %{
        "count" => 600,
        "maximum" => 230_700,
        "mean" => 230_299.3333,
        "minimum" => 229_900,
        "variance" => 27299.555555551728
      }
    }

    mock(fn
      %{
        method: :get,
        url: "https://api.discovergy.com/public/v1/statistics",
        query: [
          meterId: "$meter_id",
          from: 1_593_561_600_000,
          fields: "voltage1,voltage2,voltage3"
        ]
      } ->
        json(statistics)
    end)

    assert {:ok, statistics} ==
             Discovergy.Measurements.get_statistics(
               client,
               "$meter_id",
               ~U[2020-07-01 00:00:00Z],
               nil,
               fields: [:voltage1, :voltage2, :voltage3]
             )
  end

  test "gets load profile", %{client: client} do
    raw_load_profile =
      <<2>> <>
        """
        P.01(1200601001500)(00000000)(15)(8)(1.29)(kWh)(2.29)(kWh)(3.29)(kvarh)(4.29)(kvarh)(5.29)(kvarh)(6.29)(kvarh)(7.29)(kvarh)(8.2)(kvarh)
        (0.0000)(0.0000)(0.0000)(0.0035)(0.0000)(0.0000)(0.0031)(0.0004)
        (0.0001)(0.0001)(0.0000)(0.0035)(0.0000)(0.0000)(0.0031)(0.0005)
        """

    mock(fn
      %{
        method: :get,
        query: [meterId: "$meter_id", year: 2020, month: 6, day: 1],
        url: "https://api.discovergy.com/public/v1/raw_load_profile"
      } ->
        json(raw_load_profile)
    end)

    assert {:ok, raw_load_profile} ==
             Discovergy.Measurements.get_raw_load_profile(client, "$meter_id", ~D{2020-06-01})
  end
end
