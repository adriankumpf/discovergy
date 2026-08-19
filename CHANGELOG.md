# Changelog

## Unreleased

### Breaking Changes

- Remove `Discovergy.Measurements.get_raw_load_profile/3`. The `/raw_load_profile` endpoint no longer exists and the API returns a 404 for every request, so the function could not succeed.
- Require Elixir 1.15. The `finch`, `mint` and `hpax` releases carrying the fixes for [CVE-2026-58226](https://osv.dev/vulnerability/EEF-CVE-2026-58226), [CVE-2026-49754](https://osv.dev/vulnerability/EEF-CVE-2026-49754) and [CVE-2026-48862](https://osv.dev/vulnerability/EEF-CVE-2026-48862) no longer compile on older versions.
- Take the end of the interval as a `:to` option rather than a positional argument in `Discovergy.Measurements.get_readings/4`, `Discovergy.Measurements.get_statistics/4` and `Discovergy.Disaggregation.get_energy_by_device_measurements/4`. The API treats it as optional, and the old signature made it the fourth of five arguments, so reaching the options meant passing `nil` for it. `get_activities/4` and `get_load_profile/5` are unchanged, because the API requires both ends there.

  ```diff
  - Discovergy.Measurements.get_readings(client, meter_id, from, to, resolution: :one_day)
  + Discovergy.Measurements.get_readings(client, meter_id, from, to: to, resolution: :one_day)

  - Discovergy.Measurements.get_statistics(client, meter_id, from, nil, fields: [:energy])
  + Discovergy.Measurements.get_statistics(client, meter_id, from, fields: [:energy])
  ```

- Raise on an option the endpoint does not have. A misspelled `:resolution` or `:fields` used to be dropped silently, and the request went out without it.
- `Discovergy.WebsiteAccessCode.generate/2` returns the access code as the API sends it. It used to be decoded as a query string, and the first key of the resulting map was returned as the code.
- An unsuccessful response with an empty body is reported as `{:http_error, status}` instead of `:unknown`, which rendered as `":unknown"`.

### Bug Fixes

- Fix `Discovergy.Client.login/3` failing on a client that had already logged in. The consumer of the previous session was kept and used to sign the two requests that open the OAuth flow, which have to go out unsigned, so the API rejected them.
- Fix `Discovergy.VirtualMeters.create_virtual_meter/3` sending a `GET`. Creating a virtual meter is a `POST`; the `GET` route expects a `meterId` and rejected the call. It also returns the new meter, which is now decoded into a `Discovergy.Meter`. `meterIdsMinus` is dropped when no meters are subtracted, as was intended.
- Fix `Discovergy.Disaggregation.get_energy_by_device_measurements/4` returning measurements in an arbitrary order. They were sorted with `Date`, which only compares year, month and day, so every measurement of a day compared equal.
- Recognise content types that carry parameters, such as `application/json; charset=utf-8`. A JSON body labelled that way was handed back undecoded.
- Report a malformed response body as an error instead of raising `Jason.DecodeError`.
- Fix the typespecs of the endpoint functions, which referred to `Error.t/0` and `Meter.id/0` without an alias and so named modules that do not exist. Dialyzer treated the whole public API as unknown.

### Security

- Redact the OAuth secrets from `Discovergy.Client`, `Discovergy.OAuth.Consumer` and `Discovergy.OAuth.Token` when they are inspected, so a Logger metadata field or a crash report no longer prints the credentials of the session.

### Changes

- Document the quirks of the API: that HTTP Basic auth works and avoids the token lifecycle entirely, token expiry, the rate limits on consumer registration and authorization, the shape its errors arrive in, and the undocumented meter fields.
- Add `Discovergy.Client.reauthorize/3`, which obtains a new access token while reusing the consumer registered by `login/3`. The API rate limits `consumer_token` requests and asks clients to reuse tokens, so an application that refreshed by calling `login/3` again would eventually be answered with a `429`.
- Add the `kwh_scaling_factor`, `printed_full_serial_number`, `storage_numbers` and `submeter` fields to `Discovergy.Meter`. The API returns them but they were silently dropped.
- Fix the `Discovergy.Measurement` typespec: `values` is a map, not a list of maps.
- Document the interval limits of the disaggregation endpoints: `Discovergy.Disaggregation.get_energy_by_device_measurements/4` rejects anything longer than a week, `get_activities/4` anything longer than a month.
- Document that `DELETE /virtual_meter` answers `501` on every account tried, so a virtual meter cannot be removed through the API and the library offers no `delete_virtual_meter/2`.
- Document the `:fields` option's two traps: the names `Discovergy.Metadata.get_field_names/2` returns do not all round-trip (`storage` comes back as `storageNumber` from the reading endpoints and as `storage` from `/statistics`), and an unknown name is dropped rather than reported, except on `/statistics`, which answers `500` when every requested name is unknown.
- Treat any 2xx as a successful response.
- Bump dependencies

## v0.7.0 (2025-09-07)

- Use inexogy domain
- Require Elixir 1.11.4
- Bump dependencies

## v0.6.1 (2023-09-09)

### Bug Fixes

- Fix Protocol.UndefinedError in `Discovergy.Error.message/1`

## v0.6.0 (2023-08-26)

### Breaking Changes

- Migrate built-in HTTP from `hackney` to `Finch`
- Replace the`:adapter` with the `:client` option
- `Discovergy.Error`: Replace the `:env` field with `:response`

### Upgrade instructions

#### Dependencies

Discovergy now ships with an HTTP client based on `:finch` instead of `:hackney`.

Add `:finch` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:discovergy, "~> 0.6"},
    {:finch, "~> 0.16"},
  ]
end
```

#### HTTP client (optional)

1. Remove the `:adapter` configuration from `Discovergy.Client.new/1`:

   ```diff
   {:ok, client} = Discovergy.Client.new(
   -  adapter: {Tesla.Adapter.Gun, []}
   )
   ```

2. In `config/runtime.exs` set the `:discovergy, :client` option and to your own module that implements the `Discovergy.HTTPClient` behaviour:

   ```diff
   + config :discovergy,
   +   client: MyGunAdapter
   ```

See the documentation for `Discovergy.HTTPClient` for more information.

## v0.5.0 (2021-10-27)

- Do not reuse consumer token when logging in

## v0.4.0 (2020-07-13)

- Make `hackney` an optional dependency

## v0.3.0 (2020-07-11)

- Reuse consumer when logging in

## v0.2.0 (2020-07-07)

- Create a common struct for request & access tokens (`Discovergy.OAuth.Token`)
- Update docs and add usage examples

## v0.1.0 (2020-07-07)

- Initial Release
