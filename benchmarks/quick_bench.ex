defmodule Stellarmorphism.QuickBench do
  @moduledoc """
  Quick and simple benchmark runner that works without complex dependencies.
  """

  import Stellarmorphism.DSL, only: [core: 1, core: 2, asteroid: 1, rocket: 1, launch: 1]

  def main(args \\ []) do
    IO.puts("🌟 Stellarmorphism Quick Benchmark Suite")
    IO.puts("=" <> String.duplicate("=", 45))
    IO.puts("Elixir: #{System.version()}")
    IO.puts("OTP: #{System.otp_release()}")
    IO.puts("Schedulers: #{System.schedulers()}")
    IO.puts("=" <> String.duplicate("=", 45))

    case args do
      [] -> run_all_quick_benchmarks()
      ["construction"] -> test_construction()
      ["access"] -> test_access()
      ["traversal"] -> test_traversal()
      ["memory"] -> test_memory()
      ["comparison"] -> test_comparison()
      _ -> show_help()
    end
  end

  def run_all_quick_benchmarks do
    IO.puts("\n🚀 Running All Quick Benchmarks...")

    test_construction()
    test_access()
    test_traversal()
    test_memory()
    test_comparison()

    IO.puts("\n✅ All benchmarks completed!")
  end

  def test_construction do
    IO.puts("\n📊 Construction Performance Test")
    IO.puts("-" <> String.duplicate("-", 35))

    Benchee.run(
      %{
        "asteroid_tree_depth_3" => fn ->
          generate_asteroid_tree(3)
        end,
        "rocket_tree_depth_3" => fn ->
          generate_rocket_tree(3)
        end,
        "asteroid_tree_depth_5" => fn ->
          generate_asteroid_tree(5)
        end,
        "rocket_tree_depth_5" => fn ->
          generate_rocket_tree(5)
        end,
        "plain_map_structure" => fn ->
          %{
            data: 1,
            left: %{data: 2, left: nil, right: nil},
            right: %{data: 3, left: nil, right: nil}
          }
        end
      },
      time: 2,
      memory_time: 1,
      warmup: 0.5
    )
  end

  def test_access do
    IO.puts("\n📊 Access Pattern Performance Test")
    IO.puts("-" <> String.duplicate("-", 40))

    # Pre-generate structures
    asteroid_tree = generate_asteroid_tree(4)
    rocket_tree = generate_rocket_tree(4)

    Benchee.run(
      %{
        "asteroid_direct_access" => fn ->
          case asteroid_tree do
            core(Node, data: data, left: left, right: right) ->
              {data, left[:data], right[:data]}
            _ -> nil
          end
        end,
        "rocket_lazy_access" => fn ->
          case rocket_tree do
            core(Node, data: data, left: left_rocket, right: right_rocket) ->
              left = launch(left_rocket)
              right = launch(right_rocket)
              {data, left[:data], right[:data]}
            _ -> nil
          end
        end
      },
      time: 2,
      memory_time: 1,
      warmup: 0.5
    )
  end

  def test_traversal do
    IO.puts("\n📊 Traversal Performance Test")
    IO.puts("-" <> String.duplicate("-", 35))

    # Pre-generate structures
    asteroid_tree = generate_asteroid_tree(6)
    rocket_tree = generate_rocket_tree(6)

    Benchee.run(
      %{
        "count_asteroid_nodes" => fn ->
          count_asteroid_nodes(asteroid_tree)
        end,
        "count_rocket_nodes" => fn ->
          count_rocket_nodes(rocket_tree)
        end,
        "search_asteroid_tree" => fn ->
          search_asteroid_tree(asteroid_tree, 3)
        end,
        "search_rocket_tree" => fn ->
          search_rocket_tree(rocket_tree, 3)
        end
      },
      time: 2,
      memory_time: 1,
      warmup: 0.5
    )
  end

  def test_memory do
    IO.puts("\n📊 Memory Usage Test")
    IO.puts("-" <> String.duplicate("-", 25))

    Benchee.run(
      %{
        "asteroid_memory_depth_4" => fn ->
          measure_memory(fn -> generate_asteroid_tree(4) end)
        end,
        "rocket_memory_depth_4" => fn ->
          measure_memory(fn -> generate_rocket_tree(4) end)
        end,
        "asteroid_memory_depth_6" => fn ->
          measure_memory(fn -> generate_asteroid_tree(6) end)
        end,
        "rocket_memory_depth_6" => fn ->
          measure_memory(fn -> generate_rocket_tree(6) end)
        end
      },
      time: 2,
      memory_time: 1,
      warmup: 0.5
    )
  end

  def test_comparison do
    IO.puts("\n📊 Direct Performance Comparison")
    IO.puts("-" <> String.duplicate("-", 40))

    depths = [3, 4, 5, 6]

    Enum.each(depths, fn depth ->
      IO.puts("\nDepth #{depth} comparison:")

      asteroid_time = time_execution(fn ->
        generate_asteroid_tree(depth)
      end)

      rocket_time = time_execution(fn ->
        generate_rocket_tree(depth)
      end)

      ratio = if rocket_time > 0, do: asteroid_time / rocket_time, else: 0

      IO.puts("  Asteroid: #{Float.round(asteroid_time, 2)}ms")
      IO.puts("  Rocket:   #{Float.round(rocket_time, 2)}ms")
      IO.puts("  Ratio:    #{Float.round(ratio, 2)}x")
    end)
  end

  def show_help do
    IO.puts("\n📖 Available benchmark tests:")
    IO.puts("  construction  - Tree construction performance")
    IO.puts("  access        - Data access patterns")
    IO.puts("  traversal     - Tree traversal operations")
    IO.puts("  memory        - Memory usage analysis")
    IO.puts("  comparison    - Direct performance comparison")
    IO.puts("\nRun all tests with no arguments")
  end

  # Tree generation functions
  defp generate_asteroid_tree(depth) when depth <= 0 do
    core(Empty)
  end
  defp generate_asteroid_tree(depth) do
    core(Node,
      left: asteroid(generate_asteroid_tree(depth - 1)),
      right: asteroid(generate_asteroid_tree(depth - 1)),
      data: depth
    )
  end

  defp generate_rocket_tree(depth) when depth <= 0 do
    core(Empty)
  end
  defp generate_rocket_tree(depth) do
    core(Node,
      left: rocket(fn -> generate_rocket_tree(depth - 1) end),
      right: rocket(fn -> generate_rocket_tree(depth - 1) end),
      data: depth
    )
  end

  # Counting functions
  defp count_asteroid_nodes(core(Empty)), do: 0
  defp count_asteroid_nodes(core(Node, left: left, right: right, data: _)) do
    1 + count_asteroid_nodes(left) + count_asteroid_nodes(right)
  end
  defp count_asteroid_nodes(_), do: 0

  defp count_rocket_nodes(core(Empty)), do: 0
  defp count_rocket_nodes(core(Node, left: left_rocket, right: right_rocket, data: _)) do
    left = launch(left_rocket)
    right = launch(right_rocket)
    1 + count_rocket_nodes(left) + count_rocket_nodes(right)
  end
  defp count_rocket_nodes(_), do: 0

  # Search functions
  defp search_asteroid_tree(core(Empty), _), do: false
  defp search_asteroid_tree(core(Node, left: left, right: right, data: data), target) do
    if data == target do
      true
    else
      search_asteroid_tree(left, target) || search_asteroid_tree(right, target)
    end
  end
  defp search_asteroid_tree(_, _), do: false

  defp search_rocket_tree(core(Empty), _), do: false
  defp search_rocket_tree(core(Node, left: left_rocket, right: right_rocket, data: data), target) do
    if data == target do
      true
    else
      left = launch(left_rocket)
      right = launch(right_rocket)
      search_rocket_tree(left, target) || search_rocket_tree(right, target)
    end
  end
  defp search_rocket_tree(_, _), do: false

  # Utility functions
  defp measure_memory(fun) do
    :erlang.garbage_collect()
    initial_mem = :erlang.process_info(self(), :memory)
    result = fun.()
    final_mem = :erlang.process_info(self(), :memory)
    memory_used = elem(final_mem, 1) - elem(initial_mem, 1)
    {result, memory_used}
  end

  defp time_execution(fun) do
    start_time = :os.timestamp()
    _result = fun.()
    end_time = :os.timestamp()
    :timer.now_diff(end_time, start_time) / 1000  # Convert to milliseconds
  end
end

# Allow running as script
if System.argv() != [] do
  Stellarmorphism.QuickBench.main(System.argv())
end
