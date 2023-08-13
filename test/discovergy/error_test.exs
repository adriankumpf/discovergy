defmodule Discovergy.ErrorTest do
  use Discovergy.Case, logged_in: true, async: true

  test "returns an error struct", %{client: client} do
    error_msg = "400 Bad Request: The meter $meter_id is not a virtual meter"

    mock(fn %{url: "https://api.discovergy.com/public/v1/virtual_meter"} ->
      {:ok, 400, [], error_msg}
    end)

    assert {:error, error} = Discovergy.VirtualMeters.get_virtual_meter(client, "$meter_id")

    assert %Discovergy.Error{reason: ^error_msg, response: {400, [], ^error_msg}} =
             error

    assert Exception.message(error) == error_msg
  end
end
