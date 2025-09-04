defmodule Stellarmorphism.ScalePerformanceBench do
  @moduledoc """
  Benchmarks testing Stellarmorphism performance at various scales.

  Tests how asteroid and rocket recursion perform as data structure sizes
  grow from small to very large, including memory usage analysis.
  """

  alias Stellarmorphism.BenchmarkHelper
  import Stellarmorphism.DSL, only: [core: 1, core: 2, launch: 1]

  @tree_depths [3, 5, 7, 9]  # Reduced from 11 to prevent OOM - depth 11 creates 2047 nodes
  @tree_depths_test [3, 5, 7]  # Reduced depths for testing
  @stream_sizes [10, 50, 100, 500, 1000]  # Reduced for stability
  @workload_scales [100, 500, 1000]  # More conservative

  def run_all_benchmarks do
    IO.puts("\n📈 Stellarmorphism: Scale Performance Benchmarks")
    IO.puts("=" <> String.duplicate("=", 50))

    tree_scale_benchmarks()
    stream_scale_benchmarks()
    memory_scale_benchmarks()
    workload_scale_benchmarks()
    performance_degradation_analysis()
  end

  def tree_scale_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Tree Scale Performance: Construction",
      generate_tree_construction_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )

    BenchmarkHelper.run_benchmark(
      "Tree Scale Performance: Traversal",
      generate_tree_traversal_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def tree_scale_benchmarks_test do
    IO.puts("\n🧪 Running Tree Scale Test with Reduced Depths")

    BenchmarkHelper.run_benchmark(
      "Tree Scale Performance Test: Construction",
      generate_tree_construction_benchmarks_test(),
      :quick
    )
  end

  def stream_scale_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Stream Scale Performance",
      generate_stream_benchmarks(),
      :standard
    )
  end

  def memory_scale_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Memory Usage at Scale",
      generate_memory_benchmarks(),
      :thorough
    )
  end

  def workload_scale_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Workload Scale Performance",
      generate_workload_benchmarks(),
      :standard
    )
  end

  # Tree construction benchmarks across scales

  defp generate_tree_construction_benchmarks do
    asteroid_benchmarks = for depth <- @tree_depths, into: %{} do
      {
        "asteroid_tree_depth_#{depth}",
        fn ->
          BenchmarkHelper.generate_asteroid_tree(depth)
        end
      }
    end

    rocket_benchmarks = for depth <- @tree_depths, into: %{} do
      {
        "rocket_tree_depth_#{depth}",
        fn ->
          BenchmarkHelper.generate_rocket_tree(depth)
        end
      }
    end

    Map.merge(asteroid_benchmarks, rocket_benchmarks)
  end

  # Test version with reduced depths
  defp generate_tree_construction_benchmarks_test do
    asteroid_benchmarks = for depth <- @tree_depths_test, into: %{} do
      {
        "asteroid_tree_depth_#{depth}",
        fn ->
          BenchmarkHelper.generate_asteroid_tree(depth)
        end
      }
    end

    rocket_benchmarks = for depth <- @tree_depths_test, into: %{} do
      {
        "rocket_tree_depth_#{depth}",
        fn ->
          BenchmarkHelper.generate_rocket_tree(depth)
        end
      }
    end

    Map.merge(asteroid_benchmarks, rocket_benchmarks)
  end

  # Tree traversal benchmarks across scales (memory-optimized)

  defp generate_tree_traversal_benchmarks do
    # Use smaller subset of depths to reduce memory usage
    traversal_depths = [3, 5, 7]  # Skip depth 9 to save memory

    # Pre-generate trees for consistent testing
    asteroid_trees = for depth <- traversal_depths, into: %{} do
      {depth, BenchmarkHelper.generate_asteroid_tree(depth, fn i -> i * depth end)}
    end

    rocket_trees = for depth <- traversal_depths, into: %{} do
      {depth, BenchmarkHelper.generate_rocket_tree(depth, fn i -> i * depth end)}
    end

    # Only run traversal benchmarks (skip search to reduce memory)
    asteroid_benchmarks = for depth <- traversal_depths, into: %{} do
      tree = asteroid_trees[depth]
      {
        "traverse_asteroid_depth_#{depth}",
        fn ->
          BenchmarkHelper.count_asteroid_nodes(tree)
        end
      }
    end

    rocket_benchmarks = for depth <- traversal_depths, into: %{} do
      tree = rocket_trees[depth]
      {
        "traverse_rocket_depth_#{depth}",
        fn ->
          BenchmarkHelper.count_rocket_nodes(tree)
        end
      }
    end

    asteroid_benchmarks
    |> Map.merge(rocket_benchmarks)
  end

  # Stream benchmarks across scales

  defp generate_stream_benchmarks do
    construction_benchmarks = for size <- @stream_sizes, into: %{} do
      {
        "rocket_stream_size_#{size}",
        fn ->
          BenchmarkHelper.generate_rocket_stream(size)
        end
      }
    end

    # Pre-generate streams for traversal testing
    streams = for size <- @stream_sizes, into: %{} do
      {size, BenchmarkHelper.generate_rocket_stream(size, fn i -> i * 2 end)}
    end

    traversal_benchmarks = for size <- @stream_sizes, into: %{} do
      stream = streams[size]
      {
        "count_stream_size_#{size}",
        fn ->
          BenchmarkHelper.count_rocket_stream(stream)
        end
      }
    end

    partial_consumption_benchmarks = for size <- @stream_sizes, into: %{} do
      stream = streams[size]
      take_count = min(size, 50)  # Take at most 50 elements
      {
        "partial_stream_#{size}_take_#{take_count}",
        fn ->
          take_n_from_stream(stream, take_count)
        end
      }
    end

    construction_benchmarks
    |> Map.merge(traversal_benchmarks)
    |> Map.merge(partial_consumption_benchmarks)
  end

  # Memory usage benchmarks

  defp generate_memory_benchmarks do
    tree_memory_benchmarks = for depth <- @tree_depths, into: %{} do
      {
        "memory_asteroid_tree_depth_#{depth}",
        fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_asteroid_tree(depth)
          end)
        end
      }
    end

    rocket_memory_benchmarks = for depth <- @tree_depths, into: %{} do
      {
        "memory_rocket_tree_depth_#{depth}",
        fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_rocket_tree(depth)
          end)
        end
      }
    end

    stream_memory_benchmarks = for size <- @stream_sizes, into: %{} do
      {
        "memory_rocket_stream_size_#{size}",
        fn ->
          BenchmarkHelper.measure_memory(fn ->
            BenchmarkHelper.generate_rocket_stream(size)
          end)
        end
      }
    end

    evaluation_memory_benchmarks = for depth <- [5, 7, 9, 11], into: %{} do
      {
        "memory_deep_launch_depth_#{depth}",
        fn ->
          tree = BenchmarkHelper.generate_rocket_tree(depth)
          BenchmarkHelper.measure_memory(fn ->
            Stellarmorphism.Recursion.deep_launch(tree)
          end)
        end
      }
    end

    tree_memory_benchmarks
    |> Map.merge(rocket_memory_benchmarks)
    |> Map.merge(stream_memory_benchmarks)
    |> Map.merge(evaluation_memory_benchmarks)
  end

  # Workload scale benchmarks

  defp generate_workload_benchmarks do
    for scale <- @workload_scales, into: %{} do
      {
        "mixed_workload_scale_#{scale}",
        fn ->
          mixed_scale_workload(scale)
        end
      }
    end
    |> Map.merge(
      for scale <- @workload_scales, into: %{} do
        {
          "batch_construction_scale_#{scale}",
          fn ->
            batch_construction_workload(scale)
          end
        }
      end
    )
    |> Map.merge(
      for scale <- @workload_scales, into: %{} do
        {
          "batch_traversal_scale_#{scale}",
          fn ->
            batch_traversal_workload(scale)
          end
        }
      end
    )
  end

  defp mixed_scale_workload(scale) do
    # Create a mix of operations scaled to the workload size
    operations = [
      fn i ->
        depth = rem(i, 6) + 3
        BenchmarkHelper.generate_asteroid_tree(depth, fn x -> x * i end)
      end,
      fn i ->
        depth = rem(i, 6) + 3
        BenchmarkHelper.generate_rocket_tree(depth, fn x -> x * i end)
      end,
      fn i ->
        size = rem(i, 20) + 10
        BenchmarkHelper.generate_rocket_stream(size, fn x -> x * i end)
      end
    ]

    1..scale
    |> Enum.map(fn i ->
      operation = Enum.at(operations, rem(i, length(operations)))
      operation.(i)
    end)
    |> length()
  end

  defp batch_construction_workload(scale) do
    # Construct many trees of varying sizes
    1..scale
    |> Enum.map(fn i ->
      depth = rem(i, 8) + 3
      if rem(i, 2) == 0 do
        BenchmarkHelper.generate_asteroid_tree(depth)
      else
        BenchmarkHelper.generate_rocket_tree(depth)
      end
    end)
    |> length()
  end

  defp batch_traversal_workload(scale) do
    # Pre-generate trees for traversal
    trees = 1..div(scale, 10) |> Enum.map(fn i ->
      depth = rem(i, 6) + 4
      {
        BenchmarkHelper.generate_asteroid_tree(depth),
        BenchmarkHelper.generate_rocket_tree(depth)
      }
    end)

    # Traverse all trees
    asteroid_counts = Enum.map(trees, fn {asteroid_tree, _} ->
      BenchmarkHelper.count_asteroid_nodes(asteroid_tree)
    end)

    rocket_counts = Enum.map(trees, fn {_, rocket_tree} ->
      BenchmarkHelper.count_rocket_nodes(rocket_tree)
    end)

    {Enum.sum(asteroid_counts), Enum.sum(rocket_counts)}
  end

  # Performance degradation analysis

  def performance_degradation_analysis do
    IO.puts("\n📉 Performance Degradation Analysis")
    IO.puts(String.duplicate("-", 45))

    analyze_tree_scaling()
    analyze_stream_scaling()
    analyze_memory_scaling()
  end

  defp analyze_tree_scaling do
    IO.puts("\nTree Construction Scaling:")

    Enum.each(@tree_depths, fn depth ->
      nodes = :math.pow(2, depth) |> round()

      asteroid_time = time_execution(fn ->
        BenchmarkHelper.generate_asteroid_tree(depth)
      end)

      rocket_time = time_execution(fn ->
        BenchmarkHelper.generate_rocket_tree(depth)
      end)

      IO.puts("  Depth #{depth} (#{nodes} nodes): Asteroid #{asteroid_time}ms, Rocket #{rocket_time}ms")
    end)
  end

  defp analyze_stream_scaling do
    IO.puts("\nStream Construction Scaling:")

    Enum.each([10, 100, 1000, 5000], fn size ->
      stream_time = time_execution(fn ->
        BenchmarkHelper.generate_rocket_stream(size)
      end)

      count_time = time_execution(fn ->
        stream = BenchmarkHelper.generate_rocket_stream(size)
        BenchmarkHelper.count_rocket_stream(stream)
      end)

      IO.puts("  Size #{size}: Construction #{stream_time}ms, Full traversal #{count_time}ms")
    end)
  end

  defp analyze_memory_scaling do
    IO.puts("\nMemory Usage Scaling:")

    Enum.each([5, 7, 9, 11], fn depth ->
      {_, asteroid_memory} = BenchmarkHelper.measure_memory(fn ->
        BenchmarkHelper.generate_asteroid_tree(depth)
      end)

      {_, rocket_memory} = BenchmarkHelper.measure_memory(fn ->
        BenchmarkHelper.generate_rocket_tree(depth)
      end)

      IO.puts("  Depth #{depth}: Asteroid #{format_bytes(asteroid_memory)}, Rocket #{format_bytes(rocket_memory)}")
    end)
  end

  # Helper functions

  defp take_n_from_stream(stream, n) do
    take_n_from_stream(stream, n, [])
  end

  defp take_n_from_stream(_, 0, acc), do: Enum.reverse(acc)
  defp take_n_from_stream(core(Empty), _, acc), do: Enum.reverse(acc)
  defp take_n_from_stream(core(Cons, head: head, tail: tail_rocket), n, acc) when n > 0 do
    tail = launch(tail_rocket)
    take_n_from_stream(tail, n - 1, [head | acc])
  end
  defp take_n_from_stream(_, _, acc), do: Enum.reverse(acc)

  defp time_execution(fun) do
    start_time = :os.timestamp()
    _result = fun.()
    end_time = :os.timestamp()
    :timer.now_diff(end_time, start_time) / 1000  # Convert to milliseconds
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes}B"
  defp format_bytes(bytes) when bytes < 1024 * 1024 do
    "#{Float.round(bytes / 1024, 1)}KB"
  end
  defp format_bytes(bytes) do
    "#{Float.round(bytes / (1024 * 1024), 2)}MB"
  end

  # Individual benchmark runner

  def run_single_benchmark(benchmark_name) do
    case benchmark_name do
      "trees" -> tree_scale_benchmarks()
      "streams" -> stream_scale_benchmarks()
      "memory" -> memory_scale_benchmarks()
      "workload" -> workload_scale_benchmarks()
      "analysis" -> performance_degradation_analysis()
      _ ->
        IO.puts("Available benchmarks: trees, streams, memory, workload, analysis")
        IO.puts("Or run all with: run_all_benchmarks()")
    end
  end
end
