defmodule QCloud.Mixfile do
  use Mix.Project

  def project do
    [
      app: :qcloud,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :timex]
    ]
  end

  defp deps do
    [
      {:timex, ">= 0.0.0"},
      {:sweet_xml, ">= 0.0.0"},
      {:xml_builder, ">= 0.0.0"},
      {:jason, ">= 0.0.0"},
      {:httpoison, ">= 0.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "Aliyun Utils"
  end

  defp package do
    [
      files: ["lib", "config", "mix.exs", "README.md"],
      maintainers: ["dev800 <dev800@ku800.com>"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/dev800/qcloud-elixir.git"}
    ]
  end
end
