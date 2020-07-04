defmodule Discovergy.WebsiteAccessCode do
  @moduledoc """
  """

  use Discovergy

  @doc """
  Generates an access code that can be used to login a user into the Discovery
  Portal without the need of a password. This is useful e.g. to embed the
  Discovergy portal as an iframe into the partner's portal.

  The access code is only valid if the user to be logged in is the same user
  currently using the API or if the user currently using the API is the partner
  of the user to be logged in. The latter option to access the user of a
  partner is only available if enabled by Discovergy for a specific partner,
  please write to technical support if you need access. Please also note that
  the code returned is only valid for **3 hours**, so it should not be cached
  but requested every time it is needed. When you received an access token, the
  portal can be accessed using the URL
  https://my.discovergy.com/?email=user@example.org&code=abc123 (please replace
  `user@example.org` by the user name you want to login and `abc123` by the
  access code you retrieved). This URL can be used as the src for an iframe in
  order to embed it into an existing web application.
  """
  @spec website_access_code(Client.t(), String.t()) :: {:ok, String.t()} | {:error, Error.t()}
  def website_access_code(%Client{} = client, email) do
    with {:ok, code} <- request(client, :get, "/website_access_code", [], query: [email: email]) do
      {:ok, code |> Map.keys() |> List.first()}
    end
  end
end
