defmodule Mess.Janitor do
  @moduledoc """
  Provides functions for managing packages and handling versioning logic
  with error reporting and file operations, utilizing the `Mess` module
  for dependency parsing and file reading.
  """

  require Logger
  alias Jungle.Git

  @doc """
  Forks a package by creating a directory structure for the package and retrieving
  its version, if necessary.

  ## Parameters
    - `package`: the name of the package.
    - `repo`: optional repository URL.
    - `branch`: optional branch name.
    - `clones_dir`: optional path for storing clones.

  ## Example

      iex> Mess.Janitor.clone("my_package", "https://example.com/repo.git", "main", "/clones")
  """
  def clone(package, repo \\ nil, opts \\ []) do
    defs = opts[:defs] || [git: "deps.git", path: "deps.path"]
    # disable_package(package, defs[:path])
    repo = repo || "https://github.com/bonfire-networks/#{package}"

    # Extract repo and branch from version if necessary
    [repo_url | branch_opt] = String.split(repo, "#")
    branch = opts[:branch] || List.first(branch_opt)
    clone_dir = opts[:clone_dir] || "forks"
    # Create the clones directory
    File.mkdir_p(clone_dir)

    clone_path = Path.join([clone_dir, package])

    with {:ok, output} <- Git.clone(repo_url, branch: branch, path: clone_path) do
      IO.puts(
        "#{output}\nFork created for #{package} in #{clone_path} with repo: #{repo_url}, branch: #{branch}"
      )

      add(package, repo, :git, defs[:git] || "deps.git")
      add(package, repo, :path, defs[:path] || "deps.path")

      {:ok, output}
    end
  end

  # @doc """
  # Adds and installs a package.
  # NOTE: deprecated in favour of an Igniter task in bonfire_common

  # ## Parameters
  #   - `package`: the name of the package as a string.
  #   - `package_source`: the version, repo, or path of the package as a string.
  #   - `type`: `:hex`, `:git`, `:path`.
  #   - `def_path`: the path of the file where the package should be added, as a string.

  # ## Example

  #     iex> Mess.Janitor.install("my_package", "1.2.3", :git, "deps.git")
  #     "Installed package my_package at version 1.2.3 to file deps.git"
  # """
  # def install(package, package_source, type, def_path) do
  #   with :ok <- add(package, package_source, type, def_path) do
  #     ret =
  #       case type do
  #         # "#{package}@#{package_source}"
  #         :hex -> package
  #         :git -> "#{package}@git:#{package_source}"
  #         :path -> "#{package}@path:#{package_source}"
  #       end
  #       |> List.wrap()
  #       # run Igniter installers (if any)
  #       |> Mix.Tasks.Bonfire.Extension.Install.run()

  #     Logger.info("Installed package #{package} (#{package_source}) to file #{def_path}")

  #     ret
  #   end
  # end

  def upgrade(package, package_source, type, def_path) do
    # WIP: just modify the version in the file instead?
    old_version = disable_package(package, type, def_path)
    ret = add(package, package_source, type, def_path)
    {ret, old_version}
  end

  @doc """
  Adds a package to the specified definition file.

  ## Example

      iex> Mess.Janitor.add("my_package", "1.2.3", "/path/to/file")
      "Added package my_package at version 1.2.3 to file /path/to/file"
  """
  def add(package, package_source, type, def_path) do
    lines =
      Mess.deps([{type, def_path}], [])
      |> IO.inspect()

    #  naughty, but triggered by dev
    dep_name = String.to_atom(package)

    if pkg = find_package(lines, package) do
      IO.warn("#{package} was already added")
      IO.inspect(pkg)
      :ok
    else
      pkg =
        case type do
          :hex -> {dep_name, package_source}
          :git -> {dep_name, git: package_source}
          :path -> {dep_name, path: package_source}
        end

      # overwrite_file(def_path, lines ++ [pkg])
      append_to_file(def_path, [pkg])

      Logger.info("Added package #{package} (#{package_source}) to file #{def_path}")

      :ok
    end
  end

  @doc """
  Retrieves the package version from the specified file. If the package is found, the function
  will disable it and return the version. If the package occurs multiple times, an error is reported.

  ## Parameters
    - `package`: the name of the package to find.
    - `path`: the path of the file from which to retrieve the package version.

  ## Returns
    - The version of the package as a string, if found.

  ## Example

      iex> Mess.Janitor.disable_package("my_package", "/path/to/file")
      "1.2.3"
  """
  def disable_package(name, type, def_path) do
    # Uses Mess to read and parse dependencies from the specified path
    lines = Mess.deps([{type, def_path}], [])

    package = find_package(lines, name)

    case find_version(package) do
      nil ->
        IO.warn("No package found for #{name} in #{def_path}")
        false

      version ->
        # opts = get_opts(package)
        #  naughty, but triggered by dev
        dep_name = String.to_atom(name)

        # Update the file by marking the line as disabled, then return the version
        updated_lines =
          Enum.map(lines, fn
            {pkg, version, opts} when pkg == dep_name ->
              {pkg, version, Keyword.put(opts, :disabled, true)}

            {pkg, opts} when pkg == dep_name ->
              {pkg, Keyword.put(opts, :disabled, true)}

            line ->
              line
          end)

        overwrite_file(def_path, updated_lines) # FIXME: this should not overwrite the file otherwise we lose the comments

        version

        #   count ->
        #     Logger.error("Error: Package #{package} occurs #{count} times in file #{inspect(file)}")
        #     raise "Unexpected multiple occurrences"
    end
  end

  # TODO: for this to work we need to parse the def file including commented lines
  #   @doc """
  #   Enables a package in the specified dependency file.

  #   ## Parameters
  #     - `package`: the package name to enable.
  #     - `file`: the path to the dependency file.

  #   ## Example

  #       iex> MessCtl.enable_package("my_package", "/path/to/file")
  #   """
  #   def enable_package(package, type, def_path) do
  #     lines = Mess.deps([{type, def_path}], [])

  #     #  naughty, but triggered by dev
  #     dep_name = String.to_atom(package)

  #     updated_lines =
  #       Enum.map(lines, fn
  #         {pkg, opts} when pkg == dep_name ->
  #           {pkg, Keyword.drop(opts, [:disabled])}

  #         {pkg, version, opts} when pkg == dep_name ->
  #           {pkg, version, Keyword.drop(opts, [:disabled])}

  #         line ->
  #           line
  #       end)

  #     overwrite_file(def_path, updated_lines)
  #   end

  def get_version(package, defs) do
    get_package(defs, package)
    |> find_version()
  end

  def find_version(package, lines) do
    find_version(lines, package)
    |> find_version()
  end

  def find_version(package) do
    case package do
      {_, version} when is_binary(version) ->
        version

      {_, version, _} when is_binary(version) ->
        version

      _ ->
        nil
    end
  end

  def get_opts(package, defs) do
    get_package(defs, package)
    |> find_opts()
  end

  def find_opts(package, defs) do
    find_package(defs, package)
    |> find_opts()
  end

  def find_opts(package) do
    case package do
      {_, opts} when is_list(opts) ->
        opts

      {_, _, opts} when is_list(opts) ->
        opts

      _ ->
        []
    end
  end

  @doc """
  Checks if a given package exists in the specified file.

  ## Parameters
    - `package`: the package name as a string.
    - `file`: the file path as a string.

  ## Returns
    - `true` if the package exists; `false` otherwise.

  ## Example

      iex> MessCtl.package_exists?("my_package", path: "/path/to/file")
      true
  """
  def package_exists?(package, defs) do
    lines = mes_deps(defs)

    Enum.any?(lines, fn
      {pkg, _opts} -> Atom.to_string(pkg) == package
      {pkg, _version, _opts} -> Atom.to_string(pkg) == package
    end)
  end

  @doc """
  Retrieves the specific package data from the parsed file.

  ## Parameters
    - `path`: the path to the dependency file.
    - `package`: the name of the package to look up.

  ## Returns
    - The package data if found; otherwise, `nil`.

  ## Example

      iex> Parser.get_package("/path/to/file", "my_package")
      # The package data
  """
  def get_package(defs, package) when is_list(defs) or is_map(defs) do
    mes_deps(defs)
    |> find_package(package)
  end

  def find_package(lines, package) when is_list(lines) do
    Enum.find(lines, fn
      {pkg, _opts} -> Atom.to_string(pkg) == package
      {pkg, _version, _opts} -> Atom.to_string(pkg) == package
    end)
  end

  def mes_deps(defs) when is_list(defs) do
    Keyword.take(defs, [:hex, :git, :path])
    |> Mess.deps([])
  end

  def mes_deps(defs) when is_map(defs) do
    Map.take(defs, [:hex, :git, :path])
    |> Keyword.new()
    |> Mess.deps([])
  end

  def append_to_file(file_path, deps) do
    with {:ok, file} <- File.open(file_path, [:append]) do
      IO.write(file, format_deps(deps))
    end  
  end
  
  def overwrite_file(file_path, deps) do
    File.write!(file_path, format_deps(deps))
  end

  def format_deps(deps) do
    deps
    |> Enum.map(&format_dep/1)
    |> Enum.join("\n")
    |> IO.inspect()
  end

  defp format_dep({package, version, opts}) when is_binary(version) do
    # For hex dependencies
    "#{format_disabled?(opts)}#{Atom.to_string(package)} = \"#{version}\""
  end

  defp format_dep({package, version}) when is_binary(version) do
    # For hex dependencies
    "#{Atom.to_string(package)} = \"#{version}\""
  end

  defp format_dep({package, %{git: url, branch: branch}, opts}) do
    # For git dependencies with branch
    "#{format_disabled?(opts)}#{Atom.to_string(package)} = \"#{url}#{if branch, do: "#" <> branch}\""
  end

  defp format_dep({package, %{git: url}, opts}) do
    # For git dependencies without branch
    "#{format_disabled?(opts)}#{Atom.to_string(package)} = \"#{url}\""
  end

  defp format_dep({package, %{path: path}, opts}) do
    # For local dependencies
    "#{format_disabled?(opts)}#{Atom.to_string(package)} = \"#{path}\""
  end

  defp format_dep({package, opts}) when is_list(opts) do
    {source_opts, opts} = Keyword.split(opts, [:path, :git, :branch])
    format_dep({package, Map.new(source_opts), opts})
  end

  defp format_disabled?(opts) do
    if opts[:disabled], do: "# "
  end
end
