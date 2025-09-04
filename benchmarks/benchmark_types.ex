# Define benchmark types outside the main modules to avoid cyclic dependencies
defmodule Stellarmorphism.BenchmarkTypes do
  use Stellarmorphism

  # Phase 1: Binary Tree (recursive core layers)
  defstar BinaryTree do
    layers do
      core Empty
      core Leaf, value :: any()
      core Node,
        left :: asteroid(BinaryTree),
        right :: asteroid(BinaryTree),
        data :: any()
    end
  end

  # Phase 1: Lazy Stream (recursive core layers)
  defstar LazyStream do
    layers do
      core Empty
      core Cons,
        head :: any(),
        tail :: rocket(LazyStream)
    end
  end

  # Phase 1: Container (recursive core layers)
  defstar Container do
    layers do
      core Empty, capacity :: integer()
      core Partial,
        items :: list(),
        count :: integer(),
        capacity :: integer()
      core Full,
        items :: list(),
        capacity :: integer()
    end
  end

  # Phase 1: Mixed recursion types (recursive core layers)
  defstar HybridTree do
    layers do
      core Empty
      core EagerNode,
        value :: any(),
        children :: list()
      core LazyNode,
        value :: any(),
        children :: rocket(list())
    end
  end

  # Phase 1: Planet (simplified for testing)
  defplanet Vector do
    orbitals do
      moon elements :: list()
      moon length :: integer()
      moon capacity :: integer()
    end
  end

  # Result type for error handling benchmarks
  defstar Result do
    layers do
      core Success, value :: any()
      core Error, message :: String.t(), code :: integer()
    end
  end

  # JSON-like data structure for complex benchmarks
  defstar JsonValue do
    layers do
      core Null
      core Bool, value :: boolean()
      core Number, value :: number()
      core String, value :: String.t()
      core Array, elements :: list()
      core Object, fields :: map()
    end
  end
end
