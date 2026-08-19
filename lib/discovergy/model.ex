defmodule Discovergy.Model do
  @moduledoc false

  @typedoc "Converts the raw value of an API field before it is put into the struct."
  @type cast :: (term -> term)

  @typedoc """
  - `:cast` - converts the value of the given API field
  - `:rename` - names the struct field of an API key that does not underscore
    to it
  """
  @type opts :: [
          cast: %{optional(String.t()) => cast},
          rename: %{optional(String.t()) => atom}
        ]

  @doc """
  Builds a struct from the `{camelCasedKey, value}` pairs of an API response.

  Keys the struct does not have are dropped, so fields the API adds later do
  not break decoding.
  """
  @spec cast(module, Enumerable.t(), opts) :: struct
  def cast(module, attrs, opts \\ []) do
    opts = Keyword.validate!(opts, cast: %{}, rename: %{})

    struct(module, Enum.map(attrs, &cast_field(&1, opts)))
  end

  # A field the API sends as null stays nil rather than being handed to a cast
  # that expects a timestamp or an object.
  defp cast_field({key, nil}, opts), do: {field(key, opts[:rename]), nil}

  defp cast_field({key, value}, opts) do
    cast = Map.get(opts[:cast], key, & &1)
    {field(key, opts[:rename]), cast.(value)}
  end

  # Unknown fields stay strings, which struct/2 then ignores. Never create the
  # atom: the keys come off the wire.
  defp field(key, renames) do
    case renames do
      %{^key => field} -> field
      _ -> key |> Macro.underscore() |> String.to_existing_atom()
    end
  rescue
    ArgumentError -> key
  end
end
