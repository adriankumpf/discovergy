defmodule Discovergy.ErrorTest do
  use Discovergy.Case, async: true

  @moduletag :logged_in

  test "returns an error struct", %{client: client} do
    error_msg = "400 Bad Request: The meter $meter_id is not a virtual meter"

    mock(fn %{url: "https://api.inexogy.com/public/v1/virtual_meter"} ->
      {:ok, 400, [], error_msg}
    end)

    assert {:error, error} = Discovergy.VirtualMeters.get_virtual_meter(client, "$meter_id")

    assert %Discovergy.Error{reason: ^error_msg, response: {400, [], ^error_msg}} =
             error

    assert Exception.message(error) == error_msg
  end

  test "falls back to the status code if the response has no body", %{client: client} do
    mock(fn %{url: "https://api.inexogy.com/public/v1/meters"} -> {:ok, 502, [], ""} end)

    assert {:error, error} = Discovergy.Metadata.get_meters(client)
    assert %Discovergy.Error{reason: {:http_error, 502}, response: {502, [], ""}} = error
    assert Exception.message(error) == "HTTP 502"
  end

  test "reports a malformed response body", %{client: client} do
    mock(fn %{url: "https://api.inexogy.com/public/v1/meters"} ->
      {:ok, 200, [{"Content-Type", "application/json"}], "{"}
    end)

    assert {:error, %Discovergy.Error{reason: %Jason.DecodeError{}}} =
             Discovergy.Metadata.get_meters(client)
  end
end
