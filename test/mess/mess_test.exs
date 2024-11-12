defmodule Mess.MessTest do
  use ExUnit.Case, async: true

  setup_all do
    # Create a temporary file with sample dependency data
    hex = "data/test_parser_deps.hex"
    File.rm(hex)
    File.mkdir_p("data")

    File.write!(hex, """
    my_package = "1.2.3"
    other_package = "2.0.0"
    """)

    # Clean up file after tests
    on_exit(fn -> File.rm(hex) end)
    [hex: hex]
  end

  test "parse_file/1 returns parsed dependency data", %{hex: hex} do
    # Expect the Parser module to parse the file's contents
    expected = [
      {:my_package, "1.2.3", [override: true]},
      {:other_package, "2.0.0", [override: true]}
    ]

    assert Mess.deps([hex: hex], []) == expected
  end

  test "package_exists?/2 returns true if package exists", %{hex: hex} do
    assert Mess.Manager.package_exists?("my_package", hex: hex)
  end

  test "package_exists?/2 returns false if package does not exist", %{hex: hex} do
    refute Mess.Manager.package_exists?("nonexistent_package", hex: hex)
  end

  test "get_package/2 retrieves package data if it exists", %{hex: hex} do
    result = Mess.Manager.get_package([hex: hex], "my_package")
    assert result == {:my_package, "1.2.3", [override: true]}
  end

  test "get_package/2 returns nil if package does not exist", %{hex: hex} do
    refute Mess.Manager.get_package([hex: hex], "nonexistent_package")
  end
end
