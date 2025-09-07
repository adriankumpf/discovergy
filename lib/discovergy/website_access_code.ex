defmodule Discovergy.WebsiteAccessCode do
  @moduledoc """
  The Webste Access Code endpoint
  """

  alias Discovergy.Client

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
  [https://my.inexogy.com/?email=user@example.org&code=abc123](https://my.inexogy.com/?email=user@example.org&code=abc123)
  (please replace `user@example.org` by the user name you want to login and
  `abc123` by the access code you retrieved). This URL can be used as the src
  for an iframe in order to embed it into an existing web application.

  ## Examples

      iex> Discovergy.WebsiteAccessCode.generate(client, email)
      {:ok, "2020060515c15010e31f803ed6f578efab3381c177db15e152f94be015bd938"}

  """
  @spec generate(Client.t(), String.t()) :: {:ok, String.t()} | {:error, Error.t()}
  def generate(%Client{} = client, email) do
    with {:ok, code} <- Client.get(client, "/website_access_code", query: [email: email]) do
      {:ok, code |> Map.keys() |> List.first()}
    end
  end
end
