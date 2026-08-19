# Quirks of the API

Behaviour of the Discovergy (inexogy) API that the [official
documentation](https://api.inexogy.com/docs/) does not cover, collected from
running against it. Worth reading before deploying anything long-lived.

## Access tokens expire

They do, and not on a fixed schedule. Intervals observed in production ranged
from a few seconds to roughly 24 hours, with a cluster of expiries between
03:53 and 03:55 on separate days that looks like nightly maintenance.

Treat expiry as something that can happen at any moment rather than something
to pre-empt with a timer.

## An expired token is a 401 with an empty body

The API sends no body with it, so `Discovergy.Error` carries `reason: :unknown`
rather than a message. Match on the status, never on the reason:

```elixir
case Discovergy.Measurements.get_last_reading(client, meter_id) do
  {:ok, measurement} ->
    handle(measurement)

  {:error, %Discovergy.Error{response: {401, _, _}}} ->
    Discovergy.Client.refresh(client, email, password)

  {:error, error} ->
    handle_error(error)
end
```

## Re-authenticating on a 401 needs a backoff

A freshly issued token can be rejected within seconds of being issued. A
handler that re-authenticates on every 401 without backing off will hot loop
against `authorize`, which is rate limited (see below). Back off from the
second consecutive failure onwards.

## There is no credential-free refresh

`/oauth1/authorize` takes the email and password directly as query parameters
rather than redirecting the user to log in at the provider. So getting a new
access token always requires the user's credentials, and an application that
refreshes unattended has to keep them.

This is unlike ordinary OAuth 1.0a, where authorization is a browser redirect
and the client never sees the password, and unlike OAuth 2.0, whose
`refresh_token` grant needs no credentials at all.

## Consumer registration and authorization are rate limited per IP

Both limits are keyed to the source address, not the account, so switching
accounts does not lift them.

```
429 Too Many Requests: Rate of consumer_token requests from <ip> is too high. Please reuse tokens!
429 Too Many Requests: Rate of authorize requests from <ip> is too high.
```

Use `Discovergy.Client.refresh/3` rather than `Discovergy.Client.login/3` to
renew a token. It reuses the consumer registered by the first login and never
calls `consumer_token`. The consumer can also be persisted and handed back to
`Discovergy.Client.new/1` so it survives a restart:

```elixir
{:ok, client} = Discovergy.Client.new() |> Discovergy.Client.login(email, password)

# persist client.consumer and client.token, then later:
client = Discovergy.Client.new(consumer: consumer, token: token)
```

`authorize` is limited more tightly than `consumer_token`. Two calls in quick
succession from one address are enough to trigger it.

## Upstream errors arrive as HTML

A failing upstream returns nginx's own error page rather than JSON or the
plain-text errors the API produces itself, so `Error.reason` is a screenful of
HTML. Lead with the status when logging, or the message buries everything
around it:

```elixir
case error.response do
  {status, _, _} -> "HTTP #{status}: #{String.slice(Exception.message(error), 0, 120)}"
  nil -> Exception.message(error)
end
```

A routing-layer 404 in this form, rather than the API's plain-text `404`, means
the endpoint itself is gone.

## The meter schema is undocumented and grows

`/meters` returns fields the documentation never lists, and new ones appear
without notice. `Discovergy.Meter` ignores anything it does not model, so an
unknown field is dropped rather than raising, but it will not be available
until the struct catches up.

Which fields come back also varies by meter: `storageNumbers` is present on
some and absent on others.

## Disaggregation is capped at one week

`Discovergy.Disaggregation.get_energy_by_device_measurements/4` and
`get_activities/4` reject anything longer:

```
400 Bad Request: Duration of the data cannot be larger than 1 week
```
