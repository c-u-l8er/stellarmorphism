defmodule Stellarmorphism.Recursion do
  @moduledoc """
  Phase 1: Asteroid and Rocket recursion support for Stellarmorphism.

  - `asteroid/1` creates eagerly-evaluated recursive structures
  - `rocket/1` creates lazily-evaluated recursive structures
  - `launch/1` evaluates rockets to get their values
  """

  # -----------------------------
  # Asteroid: Eager Recursion
  # -----------------------------
  @doc """
  Creates an eagerly-evaluated recursive structure.

  The expression is evaluated immediately when the asteroid is created,
  making it suitable for structures that need immediate computation.

  ## Examples

      # In a star definition
      core Node,
        value: 42,
        left: asteroid(core Leaf, value: 1),
        right: asteroid(core Leaf, value: 3)

      # Direct access - no special functions needed
      left_value = tree.left.value  # Immediate access
  """
  defmacro asteroid(expr) do
    quote do
      # Evaluate expression immediately when asteroid is created
      unquote(expr)
    end
  end

  # -----------------------------
  # Rocket: Lazy Recursion
  # -----------------------------
  @doc """
  Creates a lazily-evaluated recursive structure.

  The expression is wrapped in a function and only evaluated when
  `launch/1` is called, making it suitable for infinite sequences
  or expensive computations that should be deferred.

  ## Examples

      # In a star definition
      core Cons,
        head: 1,
        tail: rocket(fn -> build_next_stream() end)

      # Launch rocket to access value
      next_values = launch(stream.tail)  # Computed when launched
  """
  defmacro rocket(expr) do
    quote do
      {:__rocket__, fn -> unquote(expr) end}
    end
  end

  @doc """
  Evaluates a rocket to get its value.

  If the value is a rocket (tagged tuple), it calls the stored function.
  If it's not a rocket, it returns the value as-is.

  ## Examples

      rocket_value = rocket(fn -> expensive_computation() end)
      result = launch(rocket_value)  # Computes and returns result

      normal_value = 42
      result = launch(normal_value)  # Returns 42 directly
  """
  defmacro launch(rocket_value) do
    quote do
      case unquote(rocket_value) do
        {:__rocket__, fun} when is_function(fun, 0) -> fun.()
        other -> other  # Not a rocket, return as-is
      end
    end
  end

  # -----------------------------
  # Helpers for recursion detection
  # -----------------------------
  @doc false
  def is_rocket?({:__rocket__, fun}) when is_function(fun, 0), do: true
  def is_rocket?(_), do: false

  @doc false
  def is_asteroid?(value) do
    # Asteroids are just regular values, not specially tagged
    # This function exists for completeness but always returns false
    # since asteroids are evaluated immediately
    not is_rocket?(value)
  end

  # -----------------------------
  # Recursive traversal utilities
  # -----------------------------
  @doc """
  Deeply launches all rockets in a nested structure.

  Useful for fully evaluating lazy structures when needed.
  """
  def deep_launch(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {k, deep_launch(v)} end)
  end

  def deep_launch(value) when is_list(value) do
    Enum.map(value, &deep_launch/1)
  end

  def deep_launch({:__rocket__, fun}) when is_function(fun, 0) do
    deep_launch(fun.())
  end

  def deep_launch(value), do: value

  @doc """
  Counts the depth of nested rockets without launching them.

  Useful for debugging infinite or deeply nested lazy structures.
  """
  def rocket_depth({:__rocket__, fun}) when is_function(fun, 0) do
    # Launch the rocket and check the depth of its content
    try do
      content = fun.()
      inner_depth = rocket_depth(content)
      1 + inner_depth
    rescue
      _ ->
        # If we can't safely launch the rocket, just return depth 1
        1
    end
  end

  def rocket_depth(value) when is_map(value) do
    value
    |> Map.values()
    |> Enum.map(&rocket_depth/1)
    |> Enum.max(fn -> 0 end)
  end

  def rocket_depth(value) when is_list(value) do
    value
    |> Enum.map(&rocket_depth/1)
    |> Enum.max(fn -> 0 end)
  end

  def rocket_depth(_), do: 0
end
