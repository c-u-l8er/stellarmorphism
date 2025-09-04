defmodule Stellarmorphism.AsteroidVsRocketBench do
  @moduledoc """
  Benchmarks comparing asteroid (eager) vs rocket (lazy) recursion performance.

  Tests construction time, access patterns, memory usage, and evaluation strategies
  across different data structure sizes and access patterns.
  """

  alias Stellarmorphism.BenchmarkHelper
  import Stellarmorphism.DSL, only: [core: 1, core: 2, rocket: 1, launch: 1]

  def run_all_benchmarks do
    IO.puts("\n🚀 Stellarmorphism: Asteroid vs Rocket Performance Benchmarks")
    IO.puts("=" <> String.duplicate("=", 65))

    construction_benchmarks()
    access_pattern_benchmarks()
    traversal_benchmarks()
    memory_benchmarks()
    evaluation_strategy_benchmarks()
  end

  def construction_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Construction Performance: Asteroid vs Rocket",
      %{
        "asteroid_tree_depth_5" => fn ->
          BenchmarkHelper.generate_asteroid_tree(5)
        end,
        "rocket_tree_depth_5" => fn ->
          BenchmarkHelper.generate_rocket_tree(5)
        end,
        "asteroid_tree_depth_8" => fn ->
          BenchmarkHelper.generate_asteroid_tree(8)
        end,
        "rocket_tree_depth_8" => fn ->
          BenchmarkHelper.generate_rocket_tree(8)
        end,
        "asteroid_tree_depth_9" => fn ->
          BenchmarkHelper.generate_asteroid_tree(9)
        end,
        "rocket_tree_depth_9" => fn ->
          BenchmarkHelper.generate_rocket_tree(9)
        end,
        "rocket_stream_100" => fn ->
          BenchmarkHelper.generate_rocket_stream(100)
        end,
        "rocket_stream_1000" => fn ->
          BenchmarkHelper.generate_rocket_stream(1000)
        end
      },
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def access_pattern_benchmarks do
    # Pre-generate structures for fair comparison
    asteroid_tree = BenchmarkHelper.generate_asteroid_tree(8, fn i -> i * 10 end)
    rocket_tree = BenchmarkHelper.generate_rocket_tree(8, fn i -> i * 10 end)
    rocket_stream = BenchmarkHelper.generate_rocket_stream(100, fn i -> i * 5 end)

    BenchmarkHelper.run_benchmark(
      "Access Pattern Performance: Immediate vs Lazy",
      %{
        "asteroid_direct_access" => fn ->
          # Direct access to asteroid tree data
          case asteroid_tree do
            core(Node, left: left, right: right, data: data) ->
              {data, left[:data], right[:data]}
            _ -> nil
          end
        end,
        "rocket_lazy_access" => fn ->
          # Launch rockets to access data
          case rocket_tree do
            core(Node, left: left_rocket, right: right_rocket, data: data) ->
              left = launch(left_rocket)
              right = launch(right_rocket)
              {data, left[:data], right[:data]}
            _ -> nil
          end
        end,
        "rocket_stream_head_access" => fn ->
          # Access stream head (immediate)
          case rocket_stream do
            core(Cons, head: head, tail: _) -> head
            _ -> nil
          end
        end,
        "rocket_stream_tail_access" => fn ->
          # Access stream tail (requires launch)
          case rocket_stream do
            core(Cons, head: _, tail: tail_rocket) ->
              tail = launch(tail_rocket)
              case tail do
                core(Cons, head: head, tail: _) -> head
                _ -> nil
              end
            _ -> nil
          end
        end
      },
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def traversal_benchmarks do
    # Generate test structures
    asteroid_tree_small = BenchmarkHelper.generate_asteroid_tree(6)
    rocket_tree_small = BenchmarkHelper.generate_rocket_tree(6)
    asteroid_tree_large = BenchmarkHelper.generate_asteroid_tree(10)
    rocket_tree_large = BenchmarkHelper.generate_rocket_tree(10)
    rocket_stream = BenchmarkHelper.generate_rocket_stream(50)

    BenchmarkHelper.run_benchmark(
      "Traversal Performance: Full Structure Processing",
      %{
        "count_asteroid_nodes_small" => fn ->
          BenchmarkHelper.count_asteroid_nodes(asteroid_tree_small)
        end,
        "count_rocket_nodes_small" => fn ->
          BenchmarkHelper.count_rocket_nodes(rocket_tree_small)
        end,
        "count_asteroid_nodes_large" => fn ->
          BenchmarkHelper.count_asteroid_nodes(asteroid_tree_large)
        end,
        "count_rocket_nodes_large" => fn ->
          BenchmarkHelper.count_rocket_nodes(rocket_tree_large)
        end,
        "count_rocket_stream" => fn ->
          BenchmarkHelper.count_rocket_stream(rocket_stream)
        end,
        "search_asteroid_tree_hit" => fn ->
          BenchmarkHelper.search_asteroid_tree(asteroid_tree_small, 3)
        end,
        "search_rocket_tree_hit" => fn ->
          BenchmarkHelper.search_rocket_tree(rocket_tree_small, 3)
        end,
        "search_asteroid_tree_miss" => fn ->
          BenchmarkHelper.search_asteroid_tree(asteroid_tree_small, 999)
        end,
        "search_rocket_tree_miss" => fn ->
          BenchmarkHelper.search_rocket_tree(rocket_tree_small, 999)
        end
      },
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def memory_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Memory Usage: Construction and Storage",
      %{
        "asteroid_tree_memory_small" => fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_asteroid_tree(6)
          end)
        end,
        "rocket_tree_memory_small" => fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_rocket_tree(6)
          end)
        end,
        "asteroid_tree_memory_large" => fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_asteroid_tree(9)
          end)
        end,
        "rocket_tree_memory_large" => fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_rocket_tree(9)
          end)
        end,
        "rocket_stream_memory" => fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_rocket_stream(100)
          end)
        end,
        "deep_launch_memory" => fn ->
          tree = BenchmarkHelper.generate_rocket_tree(6)
          BenchmarkHelper.measure_memory(fn ->
            Stellarmorphism.Recursion.deep_launch(tree)
          end)
        end
      },
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def evaluation_strategy_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Evaluation Strategy: Partial vs Full Evaluation",
      %{
        "partial_rocket_evaluation" => fn ->
          # Create a rocket structure and only access first level
          rocket_tree = BenchmarkHelper.generate_rocket_tree(8)
          case rocket_tree do
            core(Node, data: data, left: _, right: _) -> data
            _ -> nil
          end
        end,
        "full_rocket_evaluation" => fn ->
          # Create and fully evaluate rocket structure
          rocket_tree = BenchmarkHelper.generate_rocket_tree(8)
          Stellarmorphism.Recursion.deep_launch(rocket_tree)
        end,
        "asteroid_full_evaluation" => fn ->
          # Asteroid is always fully evaluated at construction
          BenchmarkHelper.generate_asteroid_tree(8)
        end,
        "lazy_stream_partial_consumption" => fn ->
          # Create stream and consume only first 5 elements
          stream = BenchmarkHelper.generate_rocket_stream(50)
          take_n(stream, 5)
        end,
        "lazy_stream_full_consumption" => fn ->
          # Create and fully consume stream
          stream = BenchmarkHelper.generate_rocket_stream(50)
          BenchmarkHelper.count_rocket_stream(stream)
        end,
        "fibonacci_sequence_partial" => fn ->
          # Generate fibonacci and take first 10
          fib_stream = fibonacci_stream()
          take_n(fib_stream, 10)
        end,
        "fibonacci_sequence_extended" => fn ->
          # Generate fibonacci and take first 20
          fib_stream = fibonacci_stream()
          take_n(fib_stream, 20)
        end
      },
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  # Helper functions for evaluation benchmarks

  defp take_n(_stream, 0), do: []
  defp take_n(core(Empty), _), do: []
  defp take_n(core(Cons, head: head, tail: tail_rocket), n) when n > 0 do
    tail = launch(tail_rocket)
    [head | take_n(tail, n - 1)]
  end
  defp take_n(_, _), do: []

  defp fibonacci_stream do
    fibonacci_from(0, 1)
  end

  defp fibonacci_from(a, b) do
    core(Cons,
      head: a,
      tail: rocket(fn -> fibonacci_from(b, a + b) end)
    )
  end

  # Benchmark runner for individual tests
  def run_single_benchmark(benchmark_name) do
    case benchmark_name do
      "construction" -> construction_benchmarks()
      "access" -> access_pattern_benchmarks()
      "traversal" -> traversal_benchmarks()
      "memory" -> memory_benchmarks()
      "evaluation" -> evaluation_strategy_benchmarks()
      _ ->
        IO.puts("Available benchmarks: construction, access, traversal, memory, evaluation")
        IO.puts("Or run all with: run_all_benchmarks()")
    end
  end
end
