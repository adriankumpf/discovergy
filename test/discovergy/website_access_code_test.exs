defmodule Discovergy.WebsiteAccessCodeTest do
  use Discovergy.Case, logged_in: true, async: true

  test "generates a website access code", %{client: client} do
    mock(fn
      %{
        method: :get,
        url: "https://api.inexogy.com/public/v1/website_access_code",
        query: [email: "$email"]
      } ->
        text("2020060515c15010e31f803ed6f578efab3381c177db15e152f94be015bd938")
    end)

    assert {:ok, "2020060515c15010e31f803ed6f578efab3381c177db15e152f94be015bd938"} ==
             Discovergy.WebsiteAccessCode.generate(client, "$email")
  end
end
