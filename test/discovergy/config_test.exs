defmodule Discovergy.ConfigTest do
  use ExUnit.Case, async: false

  alias Discovergy.Config
  alias Discovergy.HTTPClient

  setup do
    on_exit(fn ->
      for {key, _value} <- Application.get_all_env(:discovergy) do
        Application.delete_env(:discovergy, key)
      end
    end)
  end

  describe "client/0" do
    test "defaults to finch" do
      assert Config.client() == HTTPClient.Finch
    end

    test "read the application config" do
      Application.put_env(:discovergy, :client, MyClient)
      assert Config.client() == MyClient
    end
  end

  describe "client_pool_opts/0" do
    test "read the application config" do
      Application.put_env(:discovergy, :client_pool_opts, foo: :bar)
      assert Config.client_pool_opts() == [foo: :bar]
    end
  end

  describe "client_request_opts/0" do
    test "read the application config" do
      Application.put_env(:discovergy, :client_request_opts, receive_timeout: 5_000)
      assert Config.client_request_opts() == [receive_timeout: 5_000]
    end
  end
end
