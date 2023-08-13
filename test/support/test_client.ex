defmodule TestClient do
  @behaviour Discovergy.HTTPClient

  @impl true
  def child_spec(_pool_opts), do: nil

  @impl true
  def request(method, url, headers, body, req_opts) do
    Process.get(:request_mock, &default_mock/5).(method, url, headers, body, req_opts)
  end

  defp default_mock(method, url, headers, body, req_opts) do
    raise "request(#{inspect(binding())} is not mocked! Call mock/1"
  end
end
