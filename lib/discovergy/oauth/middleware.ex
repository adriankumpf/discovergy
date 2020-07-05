defmodule Discovergy.OAuth.Middleware do
  @behaviour Tesla.Middleware

  @impl Tesla.Middleware
  def call(env, next, opts) do
    opts = Keyword.merge(opts || [], env.opts)

    env =
      case {opts[:consumer], opts[:token]} do
        {nil, _} -> env
        {consumer, token} -> put_oauth(env, consumer, token)
      end

    Tesla.run(env, next)
  end

  defp put_oauth(%Tesla.Env{method: method, body: body} = env, consumer, token) do
    url = Tesla.build_url(env.url, env.query)

    credentials =
      OAuther.credentials(
        consumer_key: consumer.key,
        consumer_secret: consumer.secret,
        token: token && token.oauth_token,
        token_secret: token && token.oauth_token_secret
      )

    {authorization_header, req_params} =
      OAuther.sign(to_string(method), url, body, credentials)
      |> OAuther.header()

    env
    |> Tesla.put_headers([authorization_header])
    |> Tesla.put_body(req_params)
  end
end
