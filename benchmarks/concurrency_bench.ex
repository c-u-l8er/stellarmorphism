defmodule Stellarmorphism.ConcurrencyBench do
  @moduledoc """
  Benchmarks testing Stellarmorphism performance under concurrent load.

  Tests performance scaling from 1 to X processes performing various operations
  including construction, traversal, pattern matching, and mixed workloads.
  """

  alias Stellarmorphism.BenchmarkHelper
  import Stellarmorphism.DSL, only: [core: 1, core: 2, launch: 1]

  @process_counts [1, 2, 4, 8, 16, 32]
  @workload_sizes %{
    small: 100,
    medium: 500,
    large: 1000
  }

  def run_all_benchmarks do
    IO.puts("\n⚡ Stellarmorphism: Concurrency Performance Benchmarks")
    IO.puts("=" <> String.duplicate("=", 55))

    construction_concurrency_benchmarks()
    traversal_concurrency_benchmarks()
    pattern_matching_concurrency_benchmarks()
    mixed_workload_benchmarks()
    rocket_evaluation_concurrency_benchmarks()
  end

  def construction_concurrency_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Concurrent Construction Performance",
      generate_construction_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def traversal_concurrency_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Concurrent Traversal Performance",
      generate_traversal_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def pattern_matching_concurrency_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Concurrent Pattern Matching Performance",
      generate_pattern_matching_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def mixed_workload_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Mixed Concurrent Workload Performance",
      generate_mixed_workload_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  def rocket_evaluation_concurrency_benchmarks do
    BenchmarkHelper.run_benchmark(
      "Concurrent Rocket Evaluation Performance",
      generate_rocket_evaluation_benchmarks(),
      :memory_safe  # Use memory-safe config to prevent OOM
    )
  end

  # Construction benchmark generators

  defp generate_construction_benchmarks do
    for process_count <- @process_counts,
        {size_name, workload_size} <- @workload_sizes,
        into: %{} do
      {
        "asteroid_trees_#{process_count}p_#{size_name}",
        fn ->
          concurrent_asteroid_construction(process_count, workload_size)
        end
      }
    end
    |> Map.merge(
      for process_count <- @process_counts,
          {size_name, workload_size} <- @workload_sizes,
          into: %{} do
        {
          "rocket_trees_#{process_count}p_#{size_name}",
          fn ->
            concurrent_rocket_construction(process_count, workload_size)
          end
        }
      end
    )
  end

  defp concurrent_asteroid_construction(process_count, workload_size) do
    work_items = 1..workload_size |> Enum.to_list()

    BenchmarkHelper.concurrent_task(
      fn item ->
        depth = rem(item, 8) + 3  # Depth between 3-10
        BenchmarkHelper.generate_asteroid_tree(depth, fn i -> i * item end)
      end,
      work_items,
      process_count
    )
  end

  defp concurrent_rocket_construction(process_count, workload_size) do
    work_items = 1..workload_size |> Enum.to_list()

    BenchmarkHelper.concurrent_task(
      fn item ->
        depth = rem(item, 8) + 3  # Depth between 3-10
        BenchmarkHelper.generate_rocket_tree(depth, fn i -> i * item end)
      end,
      work_items,
      process_count
    )
  end

  # Traversal benchmark generators

  defp generate_traversal_benchmarks do
    # Pre-generate test structures
    test_trees = 1..100 |> Enum.map(fn i ->
      depth = rem(i, 6) + 4
      {
        BenchmarkHelper.generate_asteroid_tree(depth, fn x -> x * i end),
        BenchmarkHelper.generate_rocket_tree(depth, fn x -> x * i end)
      }
    end)

    for process_count <- @process_counts, into: %{} do
      {
        "traverse_asteroid_trees_#{process_count}p",
        fn ->
          BenchmarkHelper.concurrent_task(
            fn {asteroid_tree, _} ->
              BenchmarkHelper.count_asteroid_nodes(asteroid_tree)
            end,
            test_trees,
            process_count
          )
        end
      }
    end
    |> Map.merge(
      for process_count <- @process_counts, into: %{} do
        {
          "traverse_rocket_trees_#{process_count}p",
          fn ->
            BenchmarkHelper.concurrent_task(
              fn {_, rocket_tree} ->
                BenchmarkHelper.count_rocket_nodes(rocket_tree)
              end,
              test_trees,
              process_count
            )
          end
        }
      end
    )
  end

  # Pattern matching benchmark generators

  defp generate_pattern_matching_benchmarks do
    # Generate test data for pattern matching
    test_results = 1..200 |> Enum.map(fn i ->
      if rem(i, 3) == 0 do
        core(Success, value: "success_#{i}")
      else
        core(Error, message: "error_#{i}", code: rem(i, 500) + 100)
      end
    end)

    for process_count <- @process_counts, into: %{} do
      {
        "pattern_match_results_#{process_count}p",
        fn ->
          BenchmarkHelper.concurrent_task(
            fn result ->
              case result do
                core(Success, value: value) ->
                  String.upcase(value)
                core(Error, message: msg, code: code) ->
                  "ERROR[#{code}]: #{msg}"
                _ ->
                  "unknown"
              end
            end,
            test_results,
            process_count
          )
        end
      }
    end
    |> Map.merge(
      for process_count <- @process_counts, into: %{} do
        {
          "fusion_pattern_#{process_count}p",
          fn ->
            test_inputs = 1..100 |> Enum.map(fn i ->
              if rem(i, 2) == 0, do: {:ok, i}, else: {:error, "failed_#{i}"}
            end)

            BenchmarkHelper.concurrent_task(
              fn input ->
                case input do
                  {:ok, value} -> core(Success, value: value * 2)
                  {:error, reason} -> core(Error, message: reason, code: 400)
                end
              end,
              test_inputs,
              process_count
            )
          end
        }
      end
    )
  end

  # Mixed workload benchmark generators

  defp generate_mixed_workload_benchmarks do
    for process_count <- @process_counts, into: %{} do
      {
        "mixed_workload_#{process_count}p",
        fn ->
          mixed_concurrent_workload(process_count)
        end
      }
    end
  end

  defp mixed_concurrent_workload(process_count) do
    # Create different types of work items
    work_items = [
      {:construct_asteroid, 6},
      {:construct_rocket, 6},
      {:traverse_asteroid, BenchmarkHelper.generate_asteroid_tree(5)},
      {:traverse_rocket, BenchmarkHelper.generate_rocket_tree(5)},
      {:pattern_match, core(Success, value: "test")},
      {:search_tree, {BenchmarkHelper.generate_asteroid_tree(6), 3}},
      {:create_stream, 20},
      {:evaluate_rocket, BenchmarkHelper.generate_rocket_tree(4)}
    ] |> List.duplicate(25) |> List.flatten()

    BenchmarkHelper.concurrent_task(
      fn work_item ->
        case work_item do
          {:construct_asteroid, depth} ->
            BenchmarkHelper.generate_asteroid_tree(depth)

          {:construct_rocket, depth} ->
            BenchmarkHelper.generate_rocket_tree(depth)

          {:traverse_asteroid, tree} ->
            BenchmarkHelper.count_asteroid_nodes(tree)

          {:traverse_rocket, tree} ->
            BenchmarkHelper.count_rocket_nodes(tree)

          {:pattern_match, result} ->
            case result do
              core(Success, value: value) -> "success: #{value}"
              core(Error, message: msg, code: code) -> "error #{code}: #{msg}"
              _ -> "unknown"
            end

          {:search_tree, {tree, target}} ->
            BenchmarkHelper.search_asteroid_tree(tree, target)

          {:create_stream, count} ->
            BenchmarkHelper.generate_rocket_stream(count)

          {:evaluate_rocket, tree} ->
            Stellarmorphism.Recursion.deep_launch(tree)
        end
      end,
      work_items,
      process_count
    )
  end

  # Rocket evaluation benchmark generators

  defp generate_rocket_evaluation_benchmarks do
    # Pre-generate rocket structures
    rocket_trees = 1..50 |> Enum.map(fn i ->
      depth = rem(i, 6) + 3
      BenchmarkHelper.generate_rocket_tree(depth, fn x -> x * i end)
    end)

    rocket_streams = 1..50 |> Enum.map(fn i ->
      count = rem(i, 20) + 10
      BenchmarkHelper.generate_rocket_stream(count, fn x -> x * i end)
    end)

    for process_count <- @process_counts, into: %{} do
      {
        "deep_launch_trees_#{process_count}p",
        fn ->
          BenchmarkHelper.concurrent_task(
            fn tree ->
              Stellarmorphism.Recursion.deep_launch(tree)
            end,
            rocket_trees,
            process_count
          )
        end
      }
    end
    |> Map.merge(
      for process_count <- @process_counts, into: %{} do
        {
          "selective_launch_#{process_count}p",
          fn ->
            BenchmarkHelper.concurrent_task(
              fn tree ->
                # Only launch first level of rockets
                case tree do
                  core(Node, left: left_rocket, right: right_rocket, data: data) ->
                    left = launch(left_rocket)
                    right = launch(right_rocket)
                    {data, left[:data], right[:data]}
                  _ -> nil
                end
              end,
              rocket_trees,
              process_count
            )
          end
        }
      end
    )
    |> Map.merge(
      for process_count <- @process_counts, into: %{} do
        {
          "stream_partial_eval_#{process_count}p",
          fn ->
            BenchmarkHelper.concurrent_task(
              fn stream ->
                # Take first 5 elements from each stream
                take_n_from_stream(stream, 5)
              end,
              rocket_streams,
              process_count
            )
          end
        }
      end
    )
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

  # Process scaling analysis

  def analyze_scaling(benchmark_results) do
    IO.puts("\n📊 Concurrency Scaling Analysis")
    IO.puts(String.duplicate("-", 40))

    baseline_times = Map.new(benchmark_results, fn {name, results} ->
      case Enum.find(results, fn {proc_count, _} -> proc_count == 1 end) do
        {1, time} -> {name, time}
        _ -> {name, nil}
      end
    end)

    Enum.each(benchmark_results, fn {name, results} ->
      IO.puts("\n#{name}:")
      baseline = Map.get(baseline_times, name)

      if baseline do
        Enum.each(results, fn {proc_count, time} ->
          speedup = baseline / time
          efficiency = speedup / proc_count * 100
          IO.puts("  #{proc_count}p: #{Float.round(speedup, 2)}x speedup (#{Float.round(efficiency, 1)}% efficiency)")
        end)
      end
    end)
  end

  # Individual benchmark runner

  def run_single_benchmark(benchmark_name) do
    case benchmark_name do
      "construction" -> construction_concurrency_benchmarks()
      "traversal" -> traversal_concurrency_benchmarks()
      "pattern_matching" -> pattern_matching_concurrency_benchmarks()
      "mixed" -> mixed_workload_benchmarks()
      "rocket_evaluation" -> rocket_evaluation_concurrency_benchmarks()
      _ ->
        IO.puts("Available benchmarks: construction, traversal, pattern_matching, mixed, rocket_evaluation")
        IO.puts("Or run all with: run_all_benchmarks()")
    end
  end
end
