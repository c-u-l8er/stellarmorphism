defmodule Stellarmorphism do
  @moduledoc """
  Stellarmorphism: A stellar-themed algebraic data type DSL for Elixir.

  ## Phase 0 Features:
  - `defplanet` defines product-like types with orbitals (fields)
  - `defstar` defines sum-like types with named variants
  - `fission` performs elegant pattern matching over planets and stars
  - `fusion` constructs planets and stars using elegant constructor syntax
  - `asteroid` provides lightweight recursive/identifier helpers

  ## Phase 1 Features:
  - **Parameterized types**: `defstar BinaryTree(t) do ... end`
  - **Asteroid recursion**: `asteroid(BinaryTree(t))` - eager evaluation
  - **Rocket recursion**: `rocket(LazyStream(t))` - lazy evaluation
  - **Launch rockets**: `launch(rocket_value)` - evaluate lazy structures
  - **Enhanced constructors** with type parameters and constraints
  - **Variable arguments** in fusion/fission expressions

  ## Usage
  
  Add to your modules with:

      use Stellarmorphism

  ## Examples

  ### Basic Types (Phase 0)
  
      defplanet User do
        orbitals do
          moon id :: String.t()
          moon name :: String.t()
          moon email :: String.t()
        end
      end

      defstar Result do
        layers do
          core Success, value :: any()
          core Error, message :: String.t(), code :: integer()
        end
      end

  ### Parameterized Types (Phase 1)

      defstar BinaryTree(t) do
        layers do
          core Empty
          core Leaf, value :: t
          core Node,
            left :: asteroid(BinaryTree(t)),
            right :: asteroid(BinaryTree(t)),
            data :: t
        end
      end

      defstar LazyStream(t) do
        layers do
          core Empty
          core Cons,
            head :: t,
            tail :: rocket(LazyStream(t))
        end
      end

  ### Asteroid vs Rocket Recursion

      # Asteroid: Eager evaluation - computed immediately
      tree = core Node,
        left: asteroid(core Leaf, value: 1),
        right: asteroid(core Leaf, value: 3),
        data: 2
      
      left_value = tree.left.value  # Direct access

      # Rocket: Lazy evaluation - computed on demand
      stream = core Cons,
        head: 1,
        tail: rocket(fn -> build_next_stream() end)
      
      next_stream = launch(stream.tail)  # Computed when launched
  """

  defmacro __using__(_opts) do
    quote do
      import Stellarmorphism.DSL,
        only: [
          # Phase 0: Core macros
          defplanet: 2,
          defstar: 2,
          fusion: 3,
          fission: 3,
          orbitals: 1,
          layers: 1,
          orbital: 1,
          orbital: 2,
          orbital: 3,
          moon: 1,
          core: 2,
          variant: 2,
          # Phase 0 + 1: Asteroid (legacy + new)
          asteroid: 0,
          asteroid: 1,
          # Phase 1: New recursion macros
          rocket: 1,
          launch: 1
        ]
        
      # Phase 1: Import utility modules for advanced usage
      alias Stellarmorphism.{Types, Recursion, Constructors, Registry}
    end
  end
end
