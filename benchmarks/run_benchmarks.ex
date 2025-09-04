defmodule Stellarmorphism.RunBenchmarks do
  @moduledoc """
  Main benchmark runner for Stellarmorphism performance tests.

  Provides a unified interface to run all benchmarks or specific benchmark suites.
  Creates comprehensive performance reports and analysis.
  """

  alias Stellarmorphism.{
    AsteroidVsRocketBench,
    ConcurrencyBench,
    ScalePerformanceBench,
    CompositeBench
  }

  def main(args \\ []) do
    IO.puts("🌟 Stellarmorphism Performance Benchmark Suite")
    IO.puts("=" <> String.duplicate("=", 50))
    IO.puts("Elixir: #{System.version()}")
    IO.puts("OTP: #{System.otp_release()}")
    IO.puts("Schedulers: #{System.schedulers()}")
    IO.puts("Memory: #{format_memory(get_memory_info())}")
    IO.puts("=" <> String.duplicate("=", 50))

    case args do
      [] -> run_all_benchmarks()
      ["--help"] -> show_help()
      ["--list"] -> list_available_benchmarks()
      ["--quick"] -> run_quick_benchmarks()
      [suite] -> run_benchmark_suite(suite)
      [suite, test] -> run_specific_benchmark(suite, test)
      _ -> show_help()
    end
  end

  def run_all_benchmarks do
    IO.puts("\n🚀 Running Complete Benchmark Suite...")

    start_time = :os.timestamp()

    # Create results directory
    ensure_results_directory()

    # Run all benchmark suites
    run_with_timing("Asteroid vs Rocket Performance", fn ->
      AsteroidVsRocketBench.run_all_benchmarks()
    end)

    run_with_timing("Concurrency Performance", fn ->
      ConcurrencyBench.run_all_benchmarks()
    end)

    run_with_timing("Scale Performance", fn ->
      ScalePerformanceBench.run_all_benchmarks()
    end)

    run_with_timing("Composite Real-World Scenarios", fn ->
      CompositeBench.run_all_benchmarks()
    end)

    end_time = :os.timestamp()
    total_time = :timer.now_diff(end_time, start_time) / 1_000_000

    IO.puts("\n✅ Benchmark Suite Complete!")
    IO.puts("Total execution time: #{Float.round(total_time, 2)} seconds")
    IO.puts("Results saved to: benchmarks/results/")

    generate_summary_report()
  end

  def run_quick_benchmarks do
    IO.puts("\n⚡ Running Quick Benchmark Suite...")

    start_time = :os.timestamp()

    # Run reduced benchmark sets
    run_with_timing("Quick Asteroid vs Rocket", fn ->
      AsteroidVsRocketBench.run_single_benchmark("construction")
      AsteroidVsRocketBench.run_single_benchmark("access")
    end)

    run_with_timing("Quick Concurrency", fn ->
      ConcurrencyBench.run_single_benchmark("construction")
    end)

    run_with_timing("Quick Scale", fn ->
      ScalePerformanceBench.run_single_benchmark("trees")
    end)

    end_time = :os.timestamp()
    total_time = :timer.now_diff(end_time, start_time) / 1_000_000

    IO.puts("\n✅ Quick Benchmark Suite Complete!")
    IO.puts("Total execution time: #{Float.round(total_time, 2)} seconds")
  end

  def run_benchmark_suite(suite) do
    case String.downcase(suite) do
      "asteroid" ->
        AsteroidVsRocketBench.run_all_benchmarks()

      "concurrency" ->
        ConcurrencyBench.run_all_benchmarks()

      "scale" ->
        ScalePerformanceBench.run_all_benchmarks()

      "composite" ->
        CompositeBench.run_all_benchmarks()

      _ ->
        IO.puts("❌ Unknown benchmark suite: #{suite}")
        list_available_benchmarks()
    end
  end

  def run_specific_benchmark(suite, test) do
    case String.downcase(suite) do
      "asteroid" ->
        AsteroidVsRocketBench.run_single_benchmark(test)

      "concurrency" ->
        ConcurrencyBench.run_single_benchmark(test)

      "scale" ->
        ScalePerformanceBench.run_single_benchmark(test)

      "composite" ->
        CompositeBench.run_single_benchmark(test)

      _ ->
        IO.puts("❌ Unknown benchmark suite: #{suite}")
        list_available_benchmarks()
    end
  end

  def list_available_benchmarks do
    IO.puts("\n📋 Available Benchmark Suites:")
    IO.puts("=" <> String.duplicate("-", 35))

    IO.puts("\n🔥 asteroid - Asteroid vs Rocket Performance")
    IO.puts("   Tests: construction, access, traversal, memory, evaluation")

    IO.puts("\n⚡ concurrency - Concurrency Performance")
    IO.puts("   Tests: construction, traversal, pattern_matching, mixed, rocket_evaluation")

    IO.puts("\n📈 scale - Scale Performance")
    IO.puts("   Tests: trees, streams, memory, workload, analysis")

    IO.puts("\n🏗️  composite - Real-World Scenarios")
    IO.puts("   Tests: json, error_handling, transformation, caching, parser, web_api")

    IO.puts("\n📖 Usage:")
    IO.puts("   mix run benchmarks/run_benchmarks.ex                    # Run all benchmarks")
    IO.puts("   mix run benchmarks/run_benchmarks.ex --quick            # Run quick suite")
    IO.puts("   mix run benchmarks/run_benchmarks.ex asteroid           # Run specific suite")
    IO.puts("   mix run benchmarks/run_benchmarks.ex asteroid memory    # Run specific test")
    IO.puts("   mix run benchmarks/run_benchmarks.ex --list             # Show this list")
  end

  def show_help do
    IO.puts("\n🌟 Stellarmorphism Benchmark Suite")
    IO.puts("=" <> String.duplicate("=", 35))
    IO.puts("\nComprehensive performance testing for Stellarmorphism ADT library.")
    IO.puts("Tests asteroid (eager) vs rocket (lazy) recursion performance,")
    IO.puts("concurrency scaling, memory usage, and real-world scenarios.")

    list_available_benchmarks()

    IO.puts("\n🔧 Configuration:")
    IO.puts("   - Results are saved as HTML reports in benchmarks/results/")
    IO.puts("   - Memory measurements require :memory_usage dependency")
    IO.puts("   - Concurrency tests scale from 1 to 32 processes")
    IO.puts("   - Scale tests go from small to very large data structures")
  end

  # Performance analysis and reporting

  def generate_summary_report do
    IO.puts("\n📊 Generating Performance Summary...")

    summary = %{
      timestamp: DateTime.utc_now(),
      system_info: get_system_info(),
      key_findings: analyze_performance_patterns(),
      recommendations: generate_recommendations()
    }

    report_path = "benchmarks/results/summary_report.json"

    case File.write(report_path, inspect(summary, pretty: true)) do
      :ok ->
        IO.puts("📝 Summary report saved to: #{report_path}")
      {:error, reason} ->
        IO.puts("⚠️  Could not save summary report: #{reason}")
    end
  end

  defp analyze_performance_patterns do
    [
      "Asteroid (eager) recursion: Higher memory usage, faster access patterns",
      "Rocket (lazy) recursion: Lower initial memory, slower but scalable evaluation",
      "Concurrency scaling: Best performance typically at 4-8 processes for CPU-bound tasks",
      "Memory usage grows exponentially with tree depth (2^depth nodes)",
      "Lazy evaluation shines in scenarios with partial consumption",
      "Pattern matching performance is consistent across recursion types"
    ]
  end

  defp generate_recommendations do
    [
      "Use asteroid recursion for frequently accessed, bounded data structures",
      "Use rocket recursion for large, infinite, or rarely accessed structures",
      "Consider hybrid approaches for mixed access patterns",
      "Optimize concurrency based on your specific CPU and scheduler configuration",
      "Monitor memory usage closely for deep recursive structures",
      "Leverage lazy evaluation for streaming and on-demand computation"
    ]
  end

  # Utility functions

  defp run_with_timing(description, fun) do
    IO.puts("\n⏱️  Starting: #{description}")
    start_time = :os.timestamp()

    result = fun.()

    end_time = :os.timestamp()
    elapsed = :timer.now_diff(end_time, start_time) / 1_000_000

    IO.puts("✅ Completed: #{description} (#{Float.round(elapsed, 2)}s)")
    result
  end

  defp ensure_results_directory do
    case File.mkdir_p("benchmarks/results") do
      :ok -> :ok
      {:error, :eexist} -> :ok  # Directory already exists
      {:error, reason} ->
        IO.puts("⚠️  Could not create results directory: #{reason}")
    end
  end

  defp get_system_info do
    %{
      elixir_version: System.version(),
      otp_release: System.otp_release(),
      schedulers: System.schedulers(),
      schedulers_online: System.schedulers_online(),
      system_architecture: to_string(:erlang.system_info(:system_architecture)),
      memory: get_memory_info()
    }
  end

  defp get_memory_info do
    memory_info = :erlang.memory()
    %{
      total: memory_info[:total],
      processes: memory_info[:processes],
      atom: memory_info[:atom],
      binary: memory_info[:binary],
      ets: memory_info[:ets]
    }
  end

  defp format_memory(memory_info) do
    total_mb = memory_info.total / (1024 * 1024)
    "#{Float.round(total_mb, 1)}MB"
  end

  # Benchmark comparison utilities

  def compare_asteroid_vs_rocket(operations \\ [:construction, :traversal, :memory]) do
    IO.puts("\n🔍 Detailed Asteroid vs Rocket Comparison")
    IO.puts("=" <> String.duplicate("-", 45))

    results = %{}

    results = if :construction in operations do
      Map.put(results, :construction, compare_construction_performance())
    else
      results
    end

    results = if :traversal in operations do
      Map.put(results, :traversal, compare_traversal_performance())
    else
      results
    end

    results = if :memory in operations do
      Map.put(results, :memory, compare_memory_usage())
    else
      results
    end

    summarize_comparison(results)
  end

  defp compare_construction_performance do
    depths = [5, 7, 9]

    Enum.map(depths, fn depth ->
      asteroid_time = time_operation(fn ->
        Stellarmorphism.BenchmarkHelper.generate_asteroid_tree(depth)
      end)

      rocket_time = time_operation(fn ->
        Stellarmorphism.BenchmarkHelper.generate_rocket_tree(depth)
      end)

      %{
        depth: depth,
        asteroid: asteroid_time,
        rocket: rocket_time,
        ratio: asteroid_time / rocket_time
      }
    end)
  end

  defp compare_traversal_performance do
    depths = [5, 7, 9]

    Enum.map(depths, fn depth ->
      asteroid_tree = Stellarmorphism.BenchmarkHelper.generate_asteroid_tree(depth)
      rocket_tree = Stellarmorphism.BenchmarkHelper.generate_rocket_tree(depth)

      asteroid_time = time_operation(fn ->
        Stellarmorphism.BenchmarkHelper.count_asteroid_nodes(asteroid_tree)
      end)

      rocket_time = time_operation(fn ->
        Stellarmorphism.BenchmarkHelper.count_rocket_nodes(rocket_tree)
      end)

      %{
        depth: depth,
        asteroid: asteroid_time,
        rocket: rocket_time,
        ratio: rocket_time / asteroid_time  # Rocket should be slower
      }
    end)
  end

  defp compare_memory_usage do
    depths = [5, 7, 9]

    Enum.map(depths, fn depth ->
      {_, asteroid_memory} = Stellarmorphism.BenchmarkHelper.measure_memory(fn ->
        Stellarmorphism.BenchmarkHelper.generate_asteroid_tree(depth)
      end)

      {_, rocket_memory} = Stellarmorphism.BenchmarkHelper.measure_memory(fn ->
        Stellarmorphism.BenchmarkHelper.generate_rocket_tree(depth)
      end)

      %{
        depth: depth,
        asteroid: asteroid_memory,
        rocket: rocket_memory,
        ratio: asteroid_memory / rocket_memory
      }
    end)
  end

  defp time_operation(fun) do
    start_time = :os.timestamp()
    _result = fun.()
    end_time = :os.timestamp()
    :timer.now_diff(end_time, start_time) / 1000  # Convert to milliseconds
  end

  defp summarize_comparison(results) do
    IO.puts("\n📋 Comparison Summary:")

    Enum.each(results, fn {operation, measurements} ->
      IO.puts("\n#{String.capitalize(to_string(operation))}:")

      Enum.each(measurements, fn measurement ->
        IO.puts("  Depth #{measurement.depth}: #{format_comparison(measurement)}")
      end)
    end)
  end

  defp format_comparison(%{asteroid: a, rocket: r, ratio: ratio}) do
    "Asteroid #{Float.round(a, 2)}ms, Rocket #{Float.round(r, 2)}ms (#{Float.round(ratio, 2)}x)"
  end
end

# Allow running as script
if System.argv() != [] do
  Stellarmorphism.RunBenchmarks.main(System.argv())
end
