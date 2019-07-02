defmodule Agala.Provider.Facebook.MixProject do
  use Mix.Project

  def project do
    [
      app: :agala_facebook,
      version: "2.5.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:agala, github: "IT-CTI/agala", branch: "2.5"},
      {:jason, "~> 1.1"},
      {:plug, "~> 1.6"},
      {:httpoison, "~> 1.2"},
      {:hackney, "~> 1.13"},
      {:ex_doc, "~> 0.18.0", only: :dev},
    ]
  end

  defp description do
    """
    Facebook provider for Agala framework
    """
  end

  defp package do
    [
      maintainers: ["Dmitry Rubinstein"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/agalaframework/agala_fb"},
      files: ~w(mix.exs README* CHANGELOG* lib)
    ]
  end
end
