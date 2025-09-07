# Changelog

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
