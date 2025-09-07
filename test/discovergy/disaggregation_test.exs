defmodule Discovergy.DisaggregationTest do
  use Discovergy.Case, logged_in: true, async: true

  test "gets disaggregated energy", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.inexogy.com/public/v1/disaggregation",
        query: [meterId: "$meter_id", from: "1593561600000", to: "1593648000000"]
      } ->
        json(%{
          "1593561600000" => %{
            "Backofen-1" => 0,
            "Backofen-2" => 0,
            "Durchlauferhitzer-1" => 0,
            "Durchlauferhitzer-2" => 0,
            "Durchlauferhitzer-3" => 0,
            "Elektromobilität-1" => 0,
            "Grundlast-1" => 257_500_000,
            "Kühlschrank-1" => 0,
            "Kühlschrank-2" => 0,
            "Kühlschrank-3" => 0,
            "Spülmaschine-1" => 0,
            "Waschmaschine-1" => 0
          },
          "1593562500000" => %{
            "Backofen-1" => 0,
            "Backofen-2" => 0,
            "Durchlauferhitzer-1" => 0,
            "Durchlauferhitzer-2" => 0,
            "Durchlauferhitzer-3" => 0,
            "Elektromobilität-1" => 0,
            "Grundlast-1" => 257_500_000,
            "Kühlschrank-1" => 0,
            "Kühlschrank-2" => 0,
            "Kühlschrank-3" => 0,
            "Spülmaschine-1" => 0,
            "Waschmaschine-1" => 0
          }
        })
    end)

    assert {:ok,
            [
              %Discovergy.EnergyByDeviceMeasurement{
                energy_by_device: %{
                  "Backofen-1" => 0,
                  "Backofen-2" => 0,
                  "Durchlauferhitzer-1" => 0,
                  "Durchlauferhitzer-2" => 0,
                  "Durchlauferhitzer-3" => 0,
                  "Elektromobilität-1" => 0,
                  "Grundlast-1" => 257_500_000,
                  "Kühlschrank-1" => 0,
                  "Kühlschrank-2" => 0,
                  "Kühlschrank-3" => 0,
                  "Spülmaschine-1" => 0,
                  "Waschmaschine-1" => 0
                },
                time: ~U[2020-07-01 00:00:00.000Z]
              },
              %Discovergy.EnergyByDeviceMeasurement{
                energy_by_device: %{
                  "Backofen-1" => 0,
                  "Backofen-2" => 0,
                  "Durchlauferhitzer-1" => 0,
                  "Durchlauferhitzer-2" => 0,
                  "Durchlauferhitzer-3" => 0,
                  "Elektromobilität-1" => 0,
                  "Grundlast-1" => 257_500_000,
                  "Kühlschrank-1" => 0,
                  "Kühlschrank-2" => 0,
                  "Kühlschrank-3" => 0,
                  "Spülmaschine-1" => 0,
                  "Waschmaschine-1" => 0
                },
                time: ~U[2020-07-01 00:15:00.000Z]
              }
            ]} ==
             Discovergy.Disaggregation.get_energy_by_device_measurements(
               client,
               "$meter_id",
               ~U[2020-07-01 00:00:00Z],
               ~U[2020-07-02 00:00:00Z]
             )
  end

  test "gets activities", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.inexogy.com/public/v1/activities",
        query: [meterId: "$meter_id", from: "1593561600000", to: "1593648000000"]
      } ->
        json([
          %{
            "activityId" => 37_889_619,
            "beginTime" => 1_593_565_296_000,
            "deviceId" => 1,
            "deviceName" => "REFRIGERATOR-1",
            "deviceType" => "REFRIGERATOR",
            "endTime" => 1_593_565_902_000,
            "energy" => 70_700_000
          },
          %{
            "activityId" => 37_889_620,
            "beginTime" => 1_593_567_714_000,
            "deviceId" => 1,
            "deviceName" => "REFRIGERATOR-1",
            "deviceType" => "REFRIGERATOR",
            "endTime" => 1_593_568_356_000,
            "energy" => 76_683_333
          },
          %{
            "activityId" => 37_889_621,
            "beginTime" => 1_593_570_150_000,
            "deviceId" => 1,
            "deviceName" => "REFRIGERATOR-1",
            "deviceType" => "REFRIGERATOR",
            "endTime" => 1_593_570_804_000,
            "energy" => 78_116_666
          }
        ])
    end)

    assert {:ok,
            [
              %Discovergy.DisaggregationActivity{
                activity_id: 37_889_619,
                begin_time: ~U[2020-07-01 01:01:36.000Z],
                device_id: 1,
                device_name: "REFRIGERATOR-1",
                device_type: "REFRIGERATOR",
                end_time: ~U[2020-07-01 01:11:42.000Z],
                energy: 70_700_000
              },
              %Discovergy.DisaggregationActivity{
                activity_id: 37_889_620,
                begin_time: ~U[2020-07-01 01:41:54.000Z],
                device_id: 1,
                device_name: "REFRIGERATOR-1",
                device_type: "REFRIGERATOR",
                end_time: ~U[2020-07-01 01:52:36.000Z],
                energy: 76_683_333
              },
              %Discovergy.DisaggregationActivity{
                activity_id: 37_889_621,
                begin_time: ~U[2020-07-01 02:22:30.000Z],
                device_id: 1,
                device_name: "REFRIGERATOR-1",
                device_type: "REFRIGERATOR",
                end_time: ~U[2020-07-01 02:33:24.000Z],
                energy: 78_116_666
              }
            ]} ==
             Discovergy.Disaggregation.get_activities(
               client,
               "$meter_id",
               ~U[2020-07-01 00:00:00Z],
               ~U[2020-07-02 00:00:00Z]
             )
  end
end
