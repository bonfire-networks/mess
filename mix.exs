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
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: [
        {
          :jungle,
          # path: "../jungle"
          git: "https://github.com/bonfire-networks/jungle"
        },
        {:igniter, "~> 0.4.7", only: [:dev, :test]}
      ]
    ]
  end

  def application, do: []
end
