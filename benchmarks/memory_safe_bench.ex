defmodule Stellarmorphism.MemorySafeBench do
  @moduledoc """
  Memory-safe benchmark runner with conservative limits and monitoring.

  Designed to prevent out-of-memory conditions while still providing
  useful performance comparisons.
  """

  import Stellarmorphism.DSL, only: [core: 1, core: 2, asteroid: 1, rocket: 1]

  # Conservative limits to prevent OOM
  @safe_tree_depths [3, 4, 5, 6, 7, 8]  # Max 2^8 = 256 nodes
  @safe_stream_sizes [10, 25, 50, 100, 200]
  @memory_warning_threshold 100_000_000  # 100MB

  def main(args \\ []) do
    IO.puts("🛡️  Stellarmorphism Memory-Safe Benchmark Suite")
    IO.puts("=" <> String.duplicate("=", 50))
    IO.puts("Conservative limits to prevent out-of-memory conditions")
    print_system_info()
    IO.puts("=" <> String.duplicate("=", 50))

    case args do
      [] -> run_safe_benchmarks()
      ["construction"] -> safe_construction_test()
      ["memory"] -> safe_memory_test()
      ["progressive"] -> progressive_scale_test()
      ["limits"] -> show_safe_limits()
      _ -> show_help()
    end
  end

  def run_safe_benchmarks do
    IO.puts("\n🛡️  Running Memory-Safe Benchmark Suite...")

    safe_construction_test()
    safe_memory_test()
    progressive_scale_test()

    IO.puts("\n✅ Memory-safe benchmarks completed!")
  end

  def safe_construction_test do
    IO.puts("\n📊 Safe Construction Performance Test")
    IO.puts("-" <> String.duplicate("-", 45))

    Benchee.run(
      %{
        "asteroid_tree_depth_3" => fn -> generate_asteroid_tree(3) end,
        "rocket_tree_depth_3" => fn -> generate_rocket_tree(3) end,
        "asteroid_tree_depth_5" => fn -> generate_asteroid_tree(5) end,
        "rocket_tree_depth_5" => fn -> generate_rocket_tree(5) end,
        "asteroid_tree_depth_7" => fn -> generate_asteroid_tree(7) end,
        "rocket_tree_depth_7" => fn -> generate_rocket_tree(7) end,
        "plain_map_structure" => fn ->
          %{data: 1, left: %{data: 2}, right: %{data: 3}}
        end
      },
      time: 3,
      memory_time: 2,
      warmup: 0.5
    )
  end

  def safe_memory_test do
    IO.puts("\n📊 Safe Memory Usage Test")
    IO.puts("-" <> String.duplicate("-", 35))

    Benchee.run(
      %{
        "asteroid_memory_depth_3" => fn ->
          monitor_memory(fn -> generate_asteroid_tree(3) end, "asteroid depth 3")
        end,
        "rocket_memory_depth_3" => fn ->
          monitor_memory(fn -> generate_rocket_tree(3) end, "rocket depth 3")
        end,
        "asteroid_memory_depth_5" => fn ->
          monitor_memory(fn -> generate_asteroid_tree(5) end, "asteroid depth 5")
        end,
        "rocket_memory_depth_5" => fn ->
          monitor_memory(fn -> generate_rocket_tree(5) end, "rocket depth 5")
        end,
        "asteroid_memory_depth_7" => fn ->
          monitor_memory(fn -> generate_asteroid_tree(7) end, "asteroid depth 7")
        end,
        "rocket_memory_depth_7" => fn ->
          monitor_memory(fn -> generate_rocket_tree(7) end, "rocket depth 7")
        end
      },
      time: 2,
      memory_time: 1,
      warmup: 0.5
    )
  end

  def progressive_scale_test do
    IO.puts("\n📊 Progressive Scale Test (with safety checks)")
    IO.puts("-" <> String.duplicate("-", 55))

    Enum.each(@safe_tree_depths, fn depth ->
      nodes = trunc(:math.pow(2, depth))
      estimated_memory = estimate_memory_usage(depth)

      IO.puts("\nTesting depth #{depth} (#{nodes} nodes, ~#{format_bytes(estimated_memory)})")

      if estimated_memory > @memory_warning_threshold do
        IO.puts("⚠️  Skipping depth #{depth} - estimated memory too high")
      else
        test_depth_safely(depth)
      end
    end)
  end

  def show_safe_limits do
    IO.puts("\n🛡️  Safe Benchmark Limits")
    IO.puts("=" <> String.duplicate("-", 30))

    IO.puts("\nTree Depths: #{inspect(@safe_tree_depths)}")
    IO.puts("Stream Sizes: #{inspect(@safe_stream_sizes)}")
    IO.puts("Memory Warning Threshold: #{format_bytes(@memory_warning_threshold)}")

    IO.puts("\nEstimated Memory Usage by Depth:")
    Enum.each(@safe_tree_depths, fn depth ->
      nodes = trunc(:math.pow(2, depth))
      estimated = estimate_memory_usage(depth)
      status = if estimated > @memory_warning_threshold, do: "⚠️ ", else: "✅ "
      IO.puts("  #{status}Depth #{depth}: #{nodes} nodes, ~#{format_bytes(estimated)}")
    end)
  end

  def show_help do
    IO.puts("\n📖 Memory-Safe Benchmark Options:")
    IO.puts("  construction  - Safe construction performance test")
    IO.puts("  memory        - Safe memory usage analysis")
    IO.puts("  progressive   - Progressive scale test with safety checks")
    IO.puts("  limits        - Show safe benchmark limits")
    IO.puts("\nRun all safe tests with no arguments")
  end

  # Tree generation functions (same as other benchmarks)
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

  # Safety and monitoring functions
  defp monitor_memory(fun, description) do
    :erlang.garbage_collect()

    initial_mem = :erlang.process_info(self(), :memory)
    result = fun.()
    final_mem = :erlang.process_info(self(), :memory)

    memory_used = elem(final_mem, 1) - elem(initial_mem, 1)

    if memory_used > @memory_warning_threshold do
      IO.puts("⚠️  High memory usage for #{description}: #{format_bytes(memory_used)}")
    end

    {result, memory_used}
  end

  defp test_depth_safely(depth) do
    try do
      start_mem = get_process_memory()

      # Test asteroid construction
      asteroid_time = time_execution(fn ->
        generate_asteroid_tree(depth)
      end)

      mid_mem = get_process_memory()
      :erlang.garbage_collect()

      # Test rocket construction
      rocket_time = time_execution(fn ->
        generate_rocket_tree(depth)
      end)

      end_mem = get_process_memory()

      IO.puts("  Asteroid: #{Float.round(asteroid_time, 2)}ms")
      IO.puts("  Rocket:   #{Float.round(rocket_time, 2)}ms")
      IO.puts("  Memory delta: #{format_bytes(mid_mem - start_mem)} / #{format_bytes(end_mem - mid_mem)}")

    rescue
      error ->
        IO.puts("❌ Error at depth #{depth}: #{inspect(error)}")
    end
  end

  defp estimate_memory_usage(depth) do
    nodes = trunc(:math.pow(2, depth))
    # Rough estimate: ~200 bytes per node for asteroid trees
    nodes * 200
  end

  defp get_process_memory do
    elem(:erlang.process_info(self(), :memory), 1)
  end

  defp time_execution(fun) do
    start_time = :os.timestamp()
    _result = fun.()
    end_time = :os.timestamp()
    :timer.now_diff(end_time, start_time) / 1000
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes}B"
  defp format_bytes(bytes) when bytes < 1024 * 1024 do
    "#{Float.round(bytes / 1024, 1)}KB"
  end
  defp format_bytes(bytes) do
    "#{Float.round(bytes / (1024 * 1024), 2)}MB"
  end

  defp print_system_info do
    memory_info = :erlang.memory()
    total_mb = memory_info[:total] / (1024 * 1024)

    IO.puts("System Memory: #{Float.round(total_mb, 1)}MB")
    IO.puts("Schedulers: #{System.schedulers()}")
    IO.puts("Max Tree Depth: #{Enum.max(@safe_tree_depths)} (#{trunc(:math.pow(2, Enum.max(@safe_tree_depths)))} nodes)")
  end
end

# Allow running as script
case System.argv() do
  [] -> Stellarmorphism.MemorySafeBench.main([])
  args -> Stellarmorphism.MemorySafeBench.main(args)
end
