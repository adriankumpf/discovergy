defmodule Discovergy.VirtualMetersTest do
  use Discovergy.Case, async: true

  @moduletag :logged_in

  test "gets virtual meter", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.inexogy.com/public/v1/virtual_meter",
        query: [meterId: "$meter_id"]
      } ->
        json([
          %{
            meterId: "c1972a89ce3a4d58aadcb7908a1d31c7",
            manufacturerId: "ESY",
            serialNumber: "61229886",
            fullSerialNumber: "1ESY1161229886",
            printedFullSerialNumber: "1ESY1161229886",
            location: %{
              street: "Sedanstr.",
              streetNumber: "8",
              zip: "48268",
              city: "Greven",
              country: "DE"
            },
            administrationNumber: "",
            type: "EASYMETER",
            measurementType: "ELECTRICITY",
            loadProfileType: "SLP",
            scalingFactor: 1,
            currentScalingFactor: 1,
            voltageScalingFactor: 1,
            kWhScalingFactor: 10_000_000_000,
            storageNumbers: [1, 7, 14],
            submeter: false,
            internalMeters: 1,
            firstMeasurementTime: 1_563_286_659_367,
            lastMeasurementTime: 1_594_130_690_730
          }
        ])
    end)

    assert {:ok,
            [
              %Discovergy.Meter{
                administration_number: "",
                current_scaling_factor: 1,
                first_measurement_time: 1_563_286_659_367,
                full_serial_number: "1ESY1161229886",
                internal_meters: 1,
                kwh_scaling_factor: 10_000_000_000,
                last_measurement_time: 1_594_130_690_730,
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
                printed_full_serial_number: "1ESY1161229886",
                scaling_factor: 1,
                serial_number: "61229886",
                storage_numbers: [1, 7, 14],
                submeter: false,
                type: "EASYMETER",
                voltage_scaling_factor: 1
              }
            ]} ==
             Discovergy.VirtualMeters.get_virtual_meter(client, "$meter_id")
  end

  test "creates a virtual meter", %{client: client} do
    mock(fn
      %{
        method: :post,
        url: "https://api.inexogy.com/public/v1/virtual_meter",
        query: [meterIdsPlus: "$one,$two", meterIdsMinus: "$three"]
      } ->
        json(%{meterId: "$virtual_meter_id", type: "VIRTUAL_ELECTRICITY"})
    end)

    assert {:ok, %Discovergy.Meter{meter_id: "$virtual_meter_id", type: "VIRTUAL_ELECTRICITY"}} =
             Discovergy.VirtualMeters.create_virtual_meter(client, ["$one", "$two"], ["$three"])
  end

  test "omits the subtracted meters if there are none", %{client: client} do
    mock(fn %{method: :post, query: [meterIdsPlus: "$one"]} ->
      json(%{meterId: "$virtual_meter_id"})
    end)

    assert {:ok, %Discovergy.Meter{}} =
             Discovergy.VirtualMeters.create_virtual_meter(client, ["$one"])
  end
end
