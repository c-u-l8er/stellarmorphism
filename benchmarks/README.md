# Stellarmorphism Benchmarks

This directory contains comprehensive performance benchmarks for the Stellarmorphism ADT library, focusing on the performance characteristics of asteroid (eager) vs rocket (lazy) recursion patterns.

## Benchmark Structure

```
benchmarks/
├── README.md                    # This file
├── benchmark_helper.ex          # Shared utilities and helpers
├── benchmark_types.ex           # Test type definitions
├── run_benchmarks.ex           # Main benchmark runner (advanced)
├── quick_bench.ex              # Quick performance tests
├── memory_safe_bench.ex        # Memory-safe benchmarks (recommended)
├── simple_benchmark.ex         # Basic verification tests
├── asteroid_vs_rocket_bench.ex # Core performance comparisons
├── concurrency_bench.ex        # Concurrency scaling tests
├── scale_performance_bench.ex  # Scale performance analysis
├── composite_bench.ex          # Real-world scenario tests
└── results/                    # Generated benchmark reports
    ├── *.html                  # Individual benchmark reports
    └── summary_report.json     # Overall performance summary
```

## Quick Start

```bash
# Install dependencies
mix deps.get

# RECOMMENDED: Memory-safe benchmarks (prevents OOM crashes)
mix run benchmarks/memory_safe_bench.ex

# Quick performance tests
mix run benchmarks/quick_bench.ex

# Basic verification
mix run benchmarks/simple_benchmark.ex simple

# Advanced: Full benchmark suite (may require memory adjustments)
mix run benchmarks/run_benchmarks.ex --quick
```

## ⚠️ Memory Safety Warning

Binary trees grow exponentially (2^depth nodes). Depths above 11 can cause out-of-memory crashes:
- Depth 10: 1,024 nodes
- Depth 11: 2,048 nodes
- Depth 15: 32,768 nodes (caused SIGKILL in testing)

**Always use memory-safe benchmarks for reliable testing.**

## Benchmark Categories

### 0. Memory-Safe Benchmarks (`memory_safe_bench.ex`) - **RECOMMENDED**

**Focus**: Safe performance testing with memory monitoring and conservative limits

**Tests**:
- Construction performance with safe tree depths (3-8)
- Memory usage analysis with monitoring
- Progressive scaling with safety checks
- Memory estimation and warnings

**Key Features**:
- Conservative limits prevent OOM crashes
- Real-time memory monitoring
- Progressive testing with safety checks
- Clear memory usage reporting

### 1. Quick Benchmarks (`quick_bench.ex`)

**Focus**: Fast, reliable performance comparisons

**Tests**:
- Basic construction performance (depths 3-6)
- Access pattern analysis
- Tree traversal operations
- Memory usage comparisons
- Direct performance comparisons

**Key Features**:
- Fast execution (2-3 minutes)
- Reliable results
- No memory safety issues
- Good for development testing

### 2. Asteroid vs Rocket (`asteroid_vs_rocket_bench.ex`)

**Focus**: Direct comparison between eager and lazy evaluation strategies

**Tests**:
- Construction performance across different tree depths
- Access pattern performance (direct vs launch overhead)
- Full traversal performance (counting, searching)
- Memory usage patterns
- Evaluation strategy differences (partial vs full)

**Key Insights**:
- Asteroids: Faster access, higher memory usage, exponential growth
- Rockets: Slower access, lower initial memory, better for large/infinite data
- **Memory Warning**: Large depths can cause system crashes

### 3. Concurrency Performance (`concurrency_bench.ex`)

**Focus**: Performance scaling from 1 to 32 processes

**Tests**:
- Concurrent construction of data structures
- Parallel traversal operations
- Concurrent pattern matching (fission)
- Mixed workload scenarios
- Rocket evaluation under concurrent load

**Key Insights**:
- Optimal performance typically at 4-8 processes for CPU-bound tasks
- Rocket evaluation can become a bottleneck under high concurrency
- Pattern matching scales well across process counts

### 4. Scale Performance (`scale_performance_bench.ex`)

**Focus**: Performance as data structure sizes grow

**Tests**:
- Tree construction and traversal (depth 3-15)
- Stream processing (10-10,000 elements)
- Memory usage analysis at scale
- Batch workload processing (100-5,000 items)
- Performance degradation analysis

**Key Insights**:
- Memory grows exponentially with tree depth (2^depth)
- Rocket streams excel at partial consumption scenarios
- Construction time scales predictably with structure size

### 5. Simple Verification (`simple_benchmark.ex`)

**Focus**: Basic functionality verification

**Tests**:
- Small-scale construction tests
- Basic access pattern verification
- Infrastructure validation

**Key Features**:
- Minimal resource usage
- Quick execution
- Verifies benchmark infrastructure works
- Good for CI/CD testing

### 6. Composite Real-World (`composite_bench.ex`)

**Focus**: Realistic usage patterns and workflows

**Tests**:
- JSON processing simulation (parsing, validation, transformation)
- Error handling pipelines using Result types
- Data transformation workflows (ETL-style)
- Caching simulation with lazy evaluation
- Parser combinator scenarios
- Web API request/response processing

**Key Insights**:
- Hybrid approaches (mixing asteroid/rocket) often optimal
- Lazy evaluation shines in streaming and caching scenarios
- Error handling pipelines benefit from eager evaluation

## Running Specific Tests

### Memory-Safe Benchmarks (Recommended)
```bash
mix run benchmarks/memory_safe_bench.ex construction  # Safe construction test
mix run benchmarks/memory_safe_bench.ex memory       # Memory analysis
mix run benchmarks/memory_safe_bench.ex progressive  # Progressive scaling
mix run benchmarks/memory_safe_bench.ex limits       # Show safe limits
```

### Quick Benchmarks
```bash
mix run benchmarks/quick_bench.ex construction   # Construction performance
mix run benchmarks/quick_bench.ex access        # Access patterns
mix run benchmarks/quick_bench.ex traversal     # Tree traversal
mix run benchmarks/quick_bench.ex memory        # Memory usage
mix run benchmarks/quick_bench.ex comparison    # Direct comparison
```

### Advanced Benchmarks (Use with caution)
```bash
# Asteroid vs Rocket benchmarks
mix run benchmarks/run_benchmarks.ex asteroid construction
mix run benchmarks/run_benchmarks.ex asteroid memory

# Concurrency benchmarks
mix run benchmarks/run_benchmarks.ex concurrency construction
mix run benchmarks/run_benchmarks.ex concurrency mixed

# Scale benchmarks (memory-intensive)
mix run benchmarks/run_benchmarks.ex scale trees
mix run benchmarks/run_benchmarks.ex scale memory
```

## Interpreting Results

### Performance Metrics

- **Time**: Execution time in seconds/milliseconds
- **Memory**: Memory usage in bytes/KB/MB
- **Throughput**: Operations per second
- **Scaling**: Performance ratio across different sizes/process counts

### HTML Reports

Each benchmark generates detailed HTML reports in `benchmarks/results/` containing:
- Performance comparison charts
- Memory usage graphs
- Statistical analysis (mean, median, standard deviation)
- System configuration details

### Key Performance Indicators

1. **Construction Speed**: How fast structures are built
2. **Access Speed**: Time to read data from structures  
3. **Memory Efficiency**: Memory usage patterns
4. **Concurrency Scaling**: Performance across process counts
5. **Scale Behavior**: Performance as data size grows

## Performance Guidelines

### When to Use Asteroids (Eager)
- ✅ Frequently accessed data structures
- ✅ Bounded, known-size data
- ✅ Predictable performance requirements
- ✅ Memory is abundant
- ✅ Full data processing needed

### When to Use Rockets (Lazy)
- ✅ Large or infinite data structures
- ✅ Infrequent or partial access patterns
- ✅ Memory-constrained environments
- ✅ Streaming scenarios
- ✅ On-demand computation

### Optimization Tips

1. **Profile First**: Run memory-safe benchmarks to understand your specific patterns
2. **Mix Strategies**: Use asteroids for hot paths, rockets for cold data
3. **Tune Concurrency**: Find optimal process count for your workload
4. **Monitor Memory**: Watch for exponential growth in deep structures (critical!)
5. **Consider Access Patterns**: Match evaluation strategy to usage
6. **Use Safe Limits**: Keep tree depths under 10 for production systems
7. **Memory Testing**: Always test memory usage before scaling up

## System Requirements

- **Elixir**: 1.15+ 
- **Erlang/OTP**: 25+
- **Memory**: 4GB+ recommended for full benchmark suite
- **CPU**: Multi-core recommended for concurrency tests
- **Disk**: 100MB+ for benchmark results

## Benchmark Configuration

Benchmarks use these timing configurations:

- **Quick**: 1s runtime, 0.1s warmup
- **Standard**: 3s runtime, 0.5s warmup  
- **Thorough**: 10s runtime, 2s warmup

Modify in `BenchmarkHelper.benchmark_config/1` for different requirements.

## Contributing

When adding new benchmarks:

1. Follow existing patterns in benchmark modules
2. Use `BenchmarkHelper` utilities for consistency
3. Include both asteroid and rocket variants
4. Test across multiple scales/sizes
5. Document expected performance characteristics
6. Update this README with new benchmark descriptions

## Dependencies

- `benchee`: Core benchmarking framework
- `benchee_html`: HTML report generation

Memory measurements use built-in Erlang functions (`:erlang.memory()`, `:erlang.process_info()`).

Install with: `mix deps.get`

## Memory Safety Notes

**Critical**: Binary tree structures grow exponentially. Each additional depth level doubles memory usage:
- Depth 8: 256 nodes (~50KB)
- Depth 10: 1,024 nodes (~200KB)
- Depth 12: 4,096 nodes (~800KB)
- Depth 15: 32,768 nodes (~6MB per tree)

The system experienced SIGKILL at depth 15 during testing. Always use memory-safe benchmarks for reliable results.