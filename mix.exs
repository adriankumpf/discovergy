defmodule Discovergy.MixProject do
  use Mix.Project

  @name "Discovergy"
  @version "0.3.0"
  @url "https://github.com/adriankumpf/discovergy"

  def project do
    [
      app: :discovergy,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "A simple wrapper for the Discovergy REST API",
      package: package(),
      aliases: [docs: &build_docs/1],
      deps: deps(),
      name: @name
    ]
  end

  def application do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:oauther, "~> 1.1"},
      {:tesla, "~> 1.3"},
      {:hackney, "~> 1.15"},
      {:jason, "~> 1.2"}
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["Discovergy", @version, Mix.Project.compile_path()]
    opts = ~w[--main #{@name} --source-ref v#{@version} --source-url #{@url} --config .docs.exs]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
