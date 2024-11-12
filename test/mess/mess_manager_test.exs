defmodule Mess.ManagerTest do
  use ExUnit.Case, async: true
  # import ExUnit.CaptureLog

  setup do
    path = "data/test_manager_deps"
    Path.wildcard("#{path}.*") |> Enum.each(&File.rm/1)
    File.rm_rf("data/jungle")
    File.mkdir_p("data")
    # Create a file with the dependencies
    File.write!("#{path}.hex", """
    existing_package = "1.2.3"
    # disabled_package = "2.0.0" 
    """)

    # Clean up after tests
    on_exit(fn ->
      Path.wildcard("#{path}.*") |> Enum.each(&File.rm/1)
      File.rm_rf("data/jungle")
    end)

    [hex: "#{path}.hex", git: "#{path}.git", path: "#{path}.path"]
  end

  test "install adds and installs a dep", defs do
    #  will raise "cannot install the igniter package with `mix igniter.install`. Please use `mix igniter.setup` instead" which tells us that it the igniter script was called as expected
    assert_raise ArgumentError, fn ->
      # assert {:ok, _} =
      # TODO: detect that we're using hex since a version was provided
      Mess.Manager.install("igniter", "~> 0.4.7", :hex, defs[:hex])

      # added_package = Mess.Manager.get_package(defs, "igniter")
      # assert added_package == {:igniter, "~> 0.4.7", override: true}
    end
  end

  test "add adds and but does not install a dep", defs do
    # TODO: detect that we're using hex since a version was provided
    assert :ok ==
             Mess.Manager.add("igniter", "~> 0.4.7", :hex, defs[:hex])

    added_package = Mess.Manager.get_package(defs, "igniter")
    assert added_package == {:igniter, "~> 0.4.7", override: true}
  end

  test "clone clones a repo and adds it to deps defs", defs do
    assert {:ok, _} =
             Mess.Manager.clone("jungle", "https://github.com/bonfire-networks/jungle",
               clone_dir: "data/",
               defs: defs
             )

    added_package = Mess.Manager.get_package(defs, "jungle")
    assert added_package == {:jungle, path: "data/jungle", override: true}

    # assert added_package == {:jungle, git: "https://github.com/bonfire-networks/jungle", override: true} # NOTE: also added but overridden by the path one
  end

  test "disable_package/2 returns version and disables package if enabled", %{hex: path} do
    version = Mess.Manager.disable_package("existing_package", :hex, path)
    assert version == "1.2.3"
    # After disabling, verify the package is updated in the file
    disabled_package = Mess.Manager.get_package([hex: path], "existing_package")
    refute disabled_package
    # assert updated_package == {:existing_package, "1.2.3", disabled: true}
  end

  # test "disable_package/2 returns version without disabling if already disabled",
  #      defs do
  #   package = Mess.Manager.get_package(defs, "disabled_package")
  #   refute package
  #   # assert package == {:disabled_package, "2.0.0", override: true} # TODO?

  #   version = Mess.Manager.disable_package("disabled_package", path)
  #   assert version == "2.0.0"
  #   disabled_package = Mess.Manager.get_package(defs, "disabled_package")
  #   refute disabled_package
  #   # assert disabled_package == {:disabled_package, "2.0.0", disabled: true}
  # end

  # test "enable_package/2 sets a package's enabled status to true", %{path: path} do
  #   Mess.Manager.enable_package("disabled_package", :hex, path)
  #   updated_package = Mess.Manager.get_package([hex: path], "disabled_package")
  #   assert updated_package == {:disabled_package, "2.0.0", override: true}
  # end
end
