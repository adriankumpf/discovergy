defmodule Discovergy.WebsiteAccessCodeTest do
  use Discovergy.Case, logged_in: true, async: true

  test "generates a website access code", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.discovergy.com/public/v1/website_access_code",
        query: [email: "$email"]
      } ->
        form(%{"$code" => true})
    end)

    assert {:ok, "$code"} == Discovergy.WebsiteAccessCode.generate(client, "$email")
  end
end
