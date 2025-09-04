defmodule Stellarmorphism.BenchmarkHelper do
  @moduledoc """
  Helper functions and utilities for Stellarmorphism benchmarks.

  Provides consistent benchmark setup, data generation, and reporting
  utilities across all benchmark modules.
  """

  import Stellarmorphism.DSL, only: [asteroid: 1, rocket: 1, launch: 1, core: 1, core: 2]

  @doc """
  Generates a binary tree using asteroid recursion (eager evaluation).
  """
  def generate_asteroid_tree(depth, data_fn \\ fn i -> i end) when depth >= 0 do
    if depth == 0 do
      core(Empty)
    else
      core(Node,
        left: asteroid(generate_asteroid_tree(depth - 1, data_fn)),
        right: asteroid(generate_asteroid_tree(depth - 1, data_fn)),
        data: data_fn.(depth)
      )
    end
  end

  @doc """
  Generates a binary tree using rocket recursion (lazy evaluation).
  """
  def generate_rocket_tree(depth, data_fn \\ fn i -> i end) when depth >= 0 do
    if depth == 0 do
      core(Empty)
    else
      core(Node,
        left: rocket(fn -> generate_rocket_tree(depth - 1, data_fn) end),
        right: rocket(fn -> generate_rocket_tree(depth - 1, data_fn) end),
        data: data_fn.(depth)
      )
    end
  end

  @doc """
  Generates a lazy stream with rocket recursion.
  """
  def generate_rocket_stream(count, data_fn \\ fn i -> i end) when count >= 0 do
    if count == 0 do
      core(Empty)
    else
      core(Cons,
        head: data_fn.(count),
        tail: rocket(fn -> generate_rocket_stream(count - 1, data_fn) end)
      )
    end
  end

  @doc """
  Generates a list-based tree structure for comparison.
  """
  def generate_list_tree(depth, data_fn \\ fn i -> i end) when depth >= 0 do
    if depth == 0 do
      %{type: :empty}
    else
      %{
        type: :node,
        left: generate_list_tree(depth - 1, data_fn),
        right: generate_list_tree(depth - 1, data_fn),
        data: data_fn.(depth)
      }
    end
  end

  @doc """
  Traverses an asteroid tree and counts nodes.
  """
  def count_asteroid_nodes(tree) do
    case tree do
      core(Empty) -> 0
      core(Node, left: left, right: right, data: _data) ->
        1 + count_asteroid_nodes(left) + count_asteroid_nodes(right)
      _ -> 0
    end
  end

  @doc """
  Traverses a rocket tree and counts nodes (forces evaluation).
  """
  def count_rocket_nodes(tree) do
    case tree do
      core(Empty) -> 0
      core(Node, left: left_rocket, right: right_rocket, data: _data) ->
        left = launch(left_rocket)
        right = launch(right_rocket)
        1 + count_rocket_nodes(left) + count_rocket_nodes(right)
      _ -> 0
    end
  end

  @doc """
  Counts elements in a rocket stream.
  """
  def count_rocket_stream(stream) do
    case stream do
      core(Empty) -> 0
      core(Cons, head: _head, tail: tail_rocket) ->
        tail = launch(tail_rocket)
        1 + count_rocket_stream(tail)
      _ -> 0
    end
  end

  @doc """
  Performs a deep search in an asteroid tree.
  """
  def search_asteroid_tree(tree, target) do
    case tree do
      core(Empty) -> false
      core(Node, left: left, right: right, data: data) ->
        if data == target do
          true
        else
          search_asteroid_tree(left, target) || search_asteroid_tree(right, target)
        end
      _ -> false
    end
  end

  @doc """
  Performs a deep search in a rocket tree.
  """
  def search_rocket_tree(tree, target) do
    case tree do
      core(Empty) -> false
      core(Node, left: left_rocket, right: right_rocket, data: data) ->
        if data == target do
          true
        else
          left = launch(left_rocket)
          right = launch(right_rocket)
          search_rocket_tree(left, target) || search_rocket_tree(right, target)
        end
      _ -> false
    end
  end

  @doc """
  Measures memory usage of a function execution.
  """
  def measure_memory(fun) do
    # Force garbage collection before measurement
    :erlang.garbage_collect()

    # Get initial memory info
    initial_mem = :erlang.process_info(self(), :memory)

    # Execute the function
    result = fun.()

    # Get final memory info
    final_mem = :erlang.process_info(self(), :memory)

    # Calculate memory difference
    memory_used = elem(final_mem, 1) - elem(initial_mem, 1)

    {result, memory_used}
  end

  @doc """
  Generates test data for various scenarios.
  """
  def generate_test_data(type, size) do
    case type do
      :integers -> 1..size |> Enum.to_list()
      :strings -> 1..size |> Enum.map(&"item_#{&1}")
      :complex -> 1..size |> Enum.map(&%{id: &1, name: "item_#{&1}", value: :rand.uniform(1000)})
      :random_integers -> 1..size |> Enum.map(fn _ -> :rand.uniform(10000) end)
    end
  end

  @doc """
  Creates a concurrent benchmark task.
  """
  def concurrent_task(task_fn, args, process_count) do
    chunk_size = max(1, div(length(args), process_count))

    args
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunk ->
      Task.async(fn ->
        Enum.map(chunk, task_fn)
      end)
    end)
    |> Task.await_many(30_000)
    |> List.flatten()
  end

  @doc """
  Benchmarking configuration presets.
  """
  def benchmark_config(type \\ :default) do
    case type do
      :quick ->
        %{
          time: 1,
          memory_time: 0.5,
          reduction_time: 0.5,
          warmup: 0.1
        }

      :standard ->
        %{
          time: 5,
          memory_time: 2,
          reduction_time: 2,
          warmup: 1
        }

      :thorough ->
        %{
          time: 10,
          memory_time: 5,
          reduction_time: 5,
          warmup: 2
        }

      :memory_safe ->
        %{
          time: 3,
          memory_time: 0,  # Disable memory measurement to save RAM
          reduction_time: 0,  # Disable reduction measurement to save RAM
          warmup: 0.5
        }

      :ultra_memory_safe ->
        %{
          time: 1,
          memory_time: 0,  # Disable memory measurement to save RAM
          reduction_time: 0,  # Disable reduction measurement to save RAM
          warmup: 0.1
        }

      :default ->
        %{
          time: 3,
          memory_time: 1,
          reduction_time: 1,
          warmup: 0.5
        }
    end
  end

  @doc """
  Standard benchmark runner with consistent formatting.
  """
  def run_benchmark(name, benchmarks, config \\ :default) do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("Running #{name}")
    IO.puts(String.duplicate("=", 60))

    # Log memory usage before benchmark
    log_memory_usage("BEFORE_#{name}")

    config_map = benchmark_config(config)

    # Log benchmark configuration
    IO.puts("Benchmark configuration: time=#{config_map.time}s, memory_time=#{config_map.memory_time}s")
    IO.puts("Number of benchmarks: #{map_size(benchmarks)}")

    final_config = [
      time: config_map.time,
      memory_time: config_map.memory_time,
      reduction_time: config_map.reduction_time,
      warmup: config_map.warmup,
      formatters: [
        Benchee.Formatters.Console,
        {Benchee.Formatters.HTML, file: "benchmarks/results/#{name |> String.downcase() |> String.replace(" ", "_")}.html"}
      ]
    ]

    # Temporarily disable hooks to avoid arity issues
    # final_config = final_config ++ [
    #   before_scenario: fn name -> log_memory_usage("BEFORE_SCENARIO_#{name}") end,
    #   after_scenario: fn name -> log_memory_usage("AFTER_SCENARIO_#{name}") end
    # ]

    IO.puts("Starting Benchee.run...")
    result = Benchee.run(benchmarks, final_config)
    IO.puts("Benchee.run completed")

    # Log memory usage after benchmark
    log_memory_usage("AFTER_#{name}")

    result
  end

  @doc """
  Logs current memory usage with a descriptive label.
  """
  def log_memory_usage(label) do
    memory_info = :erlang.memory()
    process_memory = :erlang.process_info(self(), :memory)

    total_mb = memory_info[:total] / (1024 * 1024)
    process_mb = elem(process_memory, 1) / (1024 * 1024)

    IO.puts("[MEMORY] #{label}: Total=#{Float.round(total_mb, 2)}MB, Process=#{Float.round(process_mb, 2)}MB")
  end
end
