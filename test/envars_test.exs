defmodule EnvarsTest do
  use ExUnit.Case

  describe "Envars.read!/1" do
    setup do
      System.put_env("STRING_VAR", "FOOBAR")
      System.put_env("INTEGER_VAR", "123")
      System.put_env("BOOLEAN_VAR_1", "1")
      System.put_env("BOOLEAN_VAR_2", "0")
      System.put_env("BOOLEAN_VAR_3", "True")
      System.put_env("BOOLEAN_VAR_4", "FALSE")
    end

    test "parses environment variables and uses defaults" do
      assert %{
               "STRING_VAR" => "FOOBAR",
               "INTEGER_VAR" => 123,
               "UNDEFINED_VAR" => nil,
               "BOOLEAN_VAR_1" => true,
               "BOOLEAN_VAR_2" => false,
               "BOOLEAN_VAR_3" => true,
               "BOOLEAN_VAR_4" => false,
               "DEFAULTED_VAR" => "<default value>"
             } ==
               Envars.read!(%{
                 "STRING_VAR" => [type: :string, required: true],
                 "INTEGER_VAR" => [type: :integer, default: 10],
                 "UNDEFINED_VAR" => [required: false],
                 "BOOLEAN_VAR_1" => [type: :boolean],
                 "BOOLEAN_VAR_2" => [type: :boolean],
                 "BOOLEAN_VAR_3" => [type: :boolean],
                 "BOOLEAN_VAR_4" => [type: :boolean],
                 "DEFAULTED_VAR" => [required: true, default: "<default value>"]
               })
    end

    test "raises and error with ALL missing environment variables" do
      assert_raise RuntimeError, ~r/MISSING_1\n - MISSING_2/, fn ->
        Envars.read!(%{"MISSING_1" => [], "MISSING_2" => []})
      end
    end
  end
end
