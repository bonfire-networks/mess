# Copyright (c) 2020 James Laver, mess Contributors
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
defmodule Mess.MixProject do
  use Mix.Project

  def project do
    [
      app: :mess,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      deps: [
        {
          :jungle,
          # path: "../jungle"
          git: "https://github.com/bonfire-networks/jungle"
        },
        {:igniter, "~> 0.5.21", only: [:dev, :test]}
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application, do: [extra_applications: [:logger, :runtime_tools]]
end
