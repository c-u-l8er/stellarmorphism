defmodule StellarmorphismDSLTest do
  use ExUnit.Case, async: true

  # Test the DSL in a separate module to avoid compilation issues
  test "can compile stellar DSL usage" do
    # This will test if the stellar DSL compiles without errors
    code = """
    defmodule TestStellar do
      use Stellarmorphism

      defplanet TestUser do
        orbitals do
          moon id :: String.t()
          moon name :: String.t()
          moon score :: integer()
        end
      end

      defstar TestNetwork do
        layers do
          core :Connected, primary: :any, connections: :list
          core :Isolated, person: :any
        end
      end
    end
    """

    # Try to compile the code
    result = Code.compile_string(code)
    assert is_list(result)
    assert length(result) > 0
  end
end
