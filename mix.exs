defmodule Gulp.MixProject do
  use Mix.Project

  def project do
    [
      app:      :gulp,
      version:  "0.1.0",
      elixir:   "~> 1.6",
      deps:     [],
      start_permanent: Mix.env() == :prod,
    ]
  end

  def application, do: []

end
