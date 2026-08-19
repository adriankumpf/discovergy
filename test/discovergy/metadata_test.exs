defmodule Discovergy.MetadataTest do
  use Discovergy.Case, async: true

  @moduletag :logged_in

  test "gets devices", %{client: client} do
    mock(fn
      %{url: "https://api.inexogy.com/public/v1/devices", query: [meterId: "$meter_id"]} ->
        json(["BASE_LOAD-1", "DISHWASHER-1"])
    end)

    assert {:ok, ["BASE_LOAD-1", "DISHWASHER-1"]} ==
             Discovergy.Metadata.get_devices(client, "$meter_id")
  end

  test "gets meters", %{client: client} do
    mock(fn
      %{method: :get, url: "https://api.inexogy.com/public/v1/meters"} ->
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
            ]} == Discovergy.Metadata.get_meters(client)
  end

  test "ignores fields the client does not know", %{client: client} do
    mock(fn %{url: "https://api.inexogy.com/public/v1/meters"} ->
      json([%{meterId: "$meter_id", somethingAddedLater: "surprise"}])
    end)

    assert {:ok, [%Discovergy.Meter{meter_id: "$meter_id"}]} =
             Discovergy.Metadata.get_meters(client)

    # Decoding a response must not create atoms.
    assert_raise ArgumentError, fn -> String.to_existing_atom("something_added_later") end
  end

  test "keeps a null field as nil", %{client: client} do
    mock(fn %{url: "https://api.inexogy.com/public/v1/meters"} ->
      json([%{meterId: "$meter_id", location: nil}])
    end)

    assert {:ok, [%Discovergy.Meter{location: nil}]} = Discovergy.Metadata.get_meters(client)
  end

  test "gets field names", %{client: client} do
    mock(fn
      %{url: "https://api.inexogy.com/public/v1/field_names", query: [meterId: "$meter_id"]} ->
        json(["energy", "power"])
    end)

    assert {:ok, ["energy", "power"]} == Discovergy.Metadata.get_field_names(client, "$meter_id")
  end
end
