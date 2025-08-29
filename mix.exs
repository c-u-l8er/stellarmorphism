defmodule Stellarmorphism.MixProject do
  use Mix.Project

  def project do
    [
      app: :stellarmorphism,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Stellar-themed ADT DSL: defplanet/defstar with fusion/fission",
      source_url: "https://github.com/your-org/stellarmorphism",
      homepage_url: "https://github.com/your-org/stellarmorphism",
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", ".formatter.exs", "README.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/stellarmorphism"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
