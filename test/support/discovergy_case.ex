defmodule Discovergy.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Tesla.Mock
    end
  end

  setup tags do
    opts =
      if tags[:logged_in] do
        consumer = %Discovergy.OAuth.Consumer{
          attributes: %{},
          key: "$key",
          owner: "$client_id",
          secret: "$secret"
        }

        token = %Discovergy.OAuth.Token{
          oauth_token: "$access_token",
          oauth_token_secret: "$access_token_secret"
        }

        [consumer: consumer, token: token]
      else
        []
      end

    {:ok, client: Discovergy.Client.new([{:adapter, Tesla.Mock} | opts])}
  end
end
