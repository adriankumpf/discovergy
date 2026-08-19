# Quirks of the API

Behaviour of the Discovergy (inexogy) API that the [official
documentation](https://api.inexogy.com/docs/) does not cover, collected from
running against it. Worth reading before deploying anything long-lived.

## HTTP Basic auth works, and is not documented anywhere

Every data endpoint accepts plain HTTP Basic auth with the account's email and
password:

```
curl -u 'demo@inexogy.com:demo' https://api.inexogy.com/public/v1/meters
```

Verified against `meters`, `field_names`, `last_reading`, `devices` and
`statistics`, all returning `200`. Without credentials, or with a wrong
password, the same request is a `401`.

This matters because it sidesteps everything below about tokens: nothing to
expire, no consumer to register, and neither of the rate limits. The
[ioBroker adapter](https://github.com/DrozmotiX/ioBroker.discovergy) has used
it exclusively for years.

This library uses OAuth 1.0a, which the official documentation describes as the
way in, and exposes no way to send Basic auth instead. Basic auth is
undocumented, so it carries the risk that anything undocumented does: it could
be withdrawn without notice. Everything below applies whenever OAuth is used,
which here is always.

## A public demo account exists

`demo@inexogy.com` / `demo`, with four meters covering electricity, gas and an
RLM meter. Useful for reproducing behaviour that a single-meter account cannot
show, such as the `storageNumbers` field, which some meters return and others
do not.

It is read-only in practice, so `Discovergy.VirtualMeters.create_virtual_meter/3`
cannot be exercised with it:

```
403 Forbidden: You do not have permission to create virtual meters
```

## Access tokens expire

Using OAuth, they do, and not on a fixed schedule. Intervals observed in production ranged
from a few seconds to roughly 24 hours, with a cluster of expiries between
03:53 and 03:55 on separate days that looks like nightly maintenance.

Treat expiry as something that can happen at any moment rather than something
to pre-empt with a timer.

## An expired token is a 401 with an empty body

The API sends no body with it, so `Discovergy.Error` carries
`reason: {:http_error, 401}` rather than a message. Match on the status, never
on the reason:

```elixir
case Discovergy.Measurements.get_last_reading(client, meter_id) do
  {:ok, measurement} ->
    handle(measurement)

  {:error, %Discovergy.Error{response: {401, _, _}}} ->
    Discovergy.Client.reauthorize(client, email, password)

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
renews its token unattended has to keep them.

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

Use `Discovergy.Client.reauthorize/3` rather than `Discovergy.Client.login/3` to
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

## Errors are plain text, except when they are HTML

The API writes its own errors as `text/plain`, with the status repeated in the
body: `400 Bad Request: The interval length must not exceed 1 day at this
resolution`. `Discovergy.Error` puts that whole string in `:reason`, so
`Exception.message/1` reads well on its own.

The exception is a request nginx answers itself, which comes back as its error
page and makes `Error.reason` a screenful of HTML. Lead with the status when
logging, or the message buries everything around it:

```elixir
case error.response do
  {status, _, _} -> "HTTP #{status}: #{String.slice(Exception.message(error), 0, 120)}"
  nil -> Exception.message(error)
end
```

A 404 in that form, rather than the API's own plain-text one, means the request
never reached the API and the endpoint is gone. The Swagger UI at `/docs/` is
generated from [`/docs/swagger.json`](https://api.inexogy.com/docs/swagger.json),
which lists endpoints that answer this way: the whole `Calendar` group
(`/calendars`, `/calendars/intervals`) is documented but not deployed.

## The meter schema is undocumented and grows

`/meters` returns fields the documentation never lists, and new ones appear
without notice. Against the `Meter` definition in `swagger.json`, the extras
are currently `kWhScalingFactor` and `submeter`; `Discovergy.Meter` models
both, as `kwh_scaling_factor` and `submeter`.

`Discovergy.Meter` ignores anything it does not model, so a field added later
is dropped rather than raising, but it will not be available until the struct
catches up.

Which fields come back also varies by meter: `storageNumbers` is present on
some and absent on others, so `nil` there means the meter did not report it
rather than that it has none.

## `get_field_names/2` does not round-trip into `:fields`

The names `Discovergy.Metadata.get_field_names/2` returns are not all names the
reading endpoints answer to, and feeding them straight back is the obvious
thing to do:

```elixir
{:ok, names} = Discovergy.Metadata.get_field_names(client, meter_id)
# ["energy", "power", "power1", "power2", "power3", "energyOut", "storage", "gatewayStatus"]

{:ok, measurement} = Discovergy.Measurements.get_last_reading(client, meter_id, fields: names)
Map.keys(measurement.values)
# ["energy", "energyOut", "gatewayStatus", "power", "power1", "power2", "power3", "storageNumber"]
```

`storage` went in, `storageNumber` came out, and asking for `storageNumber`
directly returns nothing. `/statistics` keys the same value as `storage`, so
the name to use depends on the endpoint.

## An unknown field name is not an error

`:fields` entries the meter does not have are dropped, and the reply is a `200`
without them, so a typo costs you a field rather than raising:

```elixir
Discovergy.Measurements.get_last_reading(client, meter_id, fields: ["powr"])
{:ok, %Discovergy.Measurement{values: %{}}}
```

`/statistics` is the exception, and only when *every* requested field is
unknown, in which case it fails rather than returning an empty map:

```
500 Internal Server Error
```

One valid field is enough to get a `200` back with the unknown ones dropped.

## `DELETE /virtual_meter` is documented but not implemented

`swagger.json` lists it, and the route is real, but it answers `501` with an
empty body:

```
$ curl -u '<email>:<password>' -X DELETE 'https://api.inexogy.com/public/v1/virtual_meter?meterId=000...0'
HTTP/2 501
content-length: 0
```

A `GET` on the same path with the same meter id gets as far as validating it:

```
400 Bad Request: Unable to find meter with meterId: 000...0
```

So the request authenticates and routes; it is the `DELETE` handler that is
missing. Confirmed on two unrelated accounts, so it is not a permission the
account lacks, which the API reports as a `403` with a message. The empty body
means this arrives as `reason: {:http_error, 501}`.

There is no `Discovergy.VirtualMeters.delete_virtual_meter/2` because there is
nothing for it to call. Virtual meters created through
`create_virtual_meter/3` cannot be removed through the API.

## The two disaggregation endpoints cap the interval differently

`Discovergy.Disaggregation.get_energy_by_device_measurements/4` rejects
anything longer than a week, `get_activities/4` anything longer than a month.
The documentation gives neither limit:

```
400 Bad Request: Duration of the data cannot be larger than 1 week. Please try for a smaller duration.
400 Bad Request: Duration of the data cannot be larger than 1 month. Please try for a smaller duration.
```
