defmodule Stellarmorphism.SimpleBenchmark do
  @moduledoc """
  Simple benchmark test to verify the infrastructure works.
  """

  import Stellarmorphism.DSL, only: [core: 1, core: 2, asteroid: 1, rocket: 1, launch: 1]

  def run_simple_test do
    IO.puts("\n🧪 Running Simple Benchmark Test...")

    # Test basic construction
    test_construction()

    # Test basic access
    test_access()

    IO.puts("✅ Simple benchmark test completed successfully!")
  end

  defp test_construction do
    IO.puts("\n📊 Testing Construction Performance...")

    Benchee.run(
      %{
        "small_asteroid_tree" => fn ->
          generate_simple_asteroid_tree(3)
        end,
        "small_rocket_tree" => fn ->
          generate_simple_rocket_tree(3)
        end,
        "basic_map_structure" => fn ->
          %{data: 1, left: %{data: 2}, right: %{data: 3}}
        end
      },
      time: 1,
      memory_time: 0.5,
      warmup: 0.1
    )
  end

  defp test_access do
    IO.puts("\n📊 Testing Access Performance...")

    # Pre-generate structures
    asteroid_tree = generate_simple_asteroid_tree(4)
    rocket_tree = generate_simple_rocket_tree(4)

    Benchee.run(
      %{
        "asteroid_access" => fn ->
          case asteroid_tree do
            core(Node, data: data, left: left, right: _) ->
              {data, left[:data]}
            _ -> nil
          end
        end,
        "rocket_access" => fn ->
          case rocket_tree do
            core(Node, data: data, left: left_rocket, right: _) ->
              left = launch(left_rocket)
              {data, left[:data]}
            _ -> nil
          end
        end
      },
      time: 1,
      memory_time: 0.5,
      warmup: 0.1
    )
  end

  # Simple tree generators
  defp generate_simple_asteroid_tree(depth) when depth <= 0 do
    core(Empty)
  end
  defp generate_simple_asteroid_tree(depth) do
    core(Node,
      left: asteroid(generate_simple_asteroid_tree(depth - 1)),
      right: asteroid(generate_simple_asteroid_tree(depth - 1)),
      data: depth
    )
  end

  defp generate_simple_rocket_tree(depth) when depth <= 0 do
    core(Empty)
  end
  defp generate_simple_rocket_tree(depth) do
    core(Node,
      left: rocket(fn -> generate_simple_rocket_tree(depth - 1) end),
      right: rocket(fn -> generate_simple_rocket_tree(depth - 1) end),
      data: depth
    )
  end
end

# Allow running as script
if System.argv() == ["simple"] do
  Stellarmorphism.SimpleBenchmark.run_simple_test()
end
