defmodule TestClient do
  @behaviour Discovergy.HTTPClient

  @impl true
  def child_spec(_pool_opts), do: nil

  @impl true
  def request(method, url, headers, body, req_opts) do
    Process.get(:request_mock, &unmocked/5).(method, url, headers, body, req_opts)
  end

  defp unmocked(method, url, _headers, body, _req_opts) do
    raise "#{method} #{url} #{inspect(body)} is not mocked, call Discovergy.Case.mock/1"
  end
end
