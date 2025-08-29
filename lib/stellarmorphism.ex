defmodule Stellarmorphism do
  @moduledoc """
  Stellarmorphism: A stellar-themed algebraic data type DSL for Elixir.

  - `defplanet` defines product-like types with orbitals (fields)
  - `defstar` defines sum-like types with named variants
  - `fission` performs elegant pattern matching over planets and stars
  - `fusion` constructs planets and stars using elegant constructor syntax
  - `asteroid` provides lightweight recursive/identifier helpers

  Use in your modules with:

      use Stellarmorphism
  """

  defmacro __using__(_opts) do
    quote do
      import Stellarmorphism.DSL,
        only: [
          defplanet: 2,
          defstar: 2,
          fusion: 2,
          fission: 2,
          asteroid: 0,
          asteroid: 1,
          orbitals: 1,
          layers: 1,
          orbital: 1,
          orbital: 2,
          orbital: 3,
          moon: 1,
          core: 2,
          variant: 2
        ]
    end
  end
end
