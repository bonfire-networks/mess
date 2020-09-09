# mess

Simple, file-based dependency management with git and local overrides.

## Installation

Download the latest version of the `mess` script into your project repo:

```shell
wget https://raw.githubusercontent.com/commonspub/mess/main/mess.exs
```

Add this line to top the top of your `mix.exs`:

```elixir
Code.eval_file("mess.exs")
```

Where you would normally return a list of dependencies, just call
`Mess.deps/1`, passing any override dependencies:

```elixir
defp deps do
  Mess.deps []
end
```

## Configuration

By default, mess will consult three files:

* `deps.path`
* `deps.git`
* `deps.hex`

These files use a simple `key="value"` format. Keys are package names
and values are hex version specs, paths or git urls. It's pretty
forgiving about whitespace, but you do need to provide the quotes. You
can add comments with `#`.

`deps.git` is treated slightly specially, in that the values may
suffix `#` and the name of a branch.

Otherwise these are all merged together, with dependencies in earlier
files taking precedence over dependencies in later files. The provided
overrides take precedence over all file data.

There isn't currently a way to provide custom options (such as
`only:`) - use overrides.

## Copyright and License

Copyright (c) 2020 James Laver, mess Contributors

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
