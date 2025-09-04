# Stellarmorphism

A stellar-themed algebraic data type DSL for Elixir that brings type-safe, elegant pattern matching and construction to your applications. Stellarmorphism provides a beautiful syntax for defining sum and product types with powerful recursion patterns.

## Features

### Phase 0: Core Foundation
- **Planets** (`defplanet`) - Product types (structs) with `orbitals` (fields)
- **Stars** (`defstar`) - Sum types with `layers` containing `core` variants  
- **Fission** - Type-safe pattern matching with star-prefixed syntax
- **Fusion** - Type-safe construction with star-prefixed syntax
- **Asteroids** - Lightweight recursive identifiers and helpers

### Phase 1: Advanced Recursion
- **Parameterized Types** - Generic types with constraints
- **Asteroid Recursion** - Eager evaluation for immediate computation
- **Rocket Recursion** - Lazy evaluation for deferred/infinite structures
- **Enhanced Constructors** - Type parameters with runtime validation
- **Mixed Recursion** - Combine eager and lazy patterns in same structure

## Installation

Add `stellarmorphism` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stellarmorphism, "~> 1.0"}
  ]
end
```

Then add to your modules:

```elixir
defmodule MyApp.Types do
  use Stellarmorphism
end
```

## Quick Start

### Basic Planets (Product Types)

```elixir
defplanet User do
  orbitals do
    moon id :: String.t()
    moon name :: String.t()
    moon email :: String.t()
    moon score :: integer()
  end
end

# Usage
user = User.new(%{id: "1", name: "Alice", email: "alice@example.com", score: 100})
```

### Basic Stars (Sum Types)

```elixir
defstar Result do
  layers do
    core Success, value :: any()
    core Error, message :: String.t(), code :: integer()
  end
end

# Construction
success = core(Success, value: "Operation completed")
error = core(Error, message: "Not found", code: 404)
```

### Fission (Pattern Matching)

```elixir
message = fission Result, result do
  core Success, value: data -> "Got: #{inspect(data)}"
  core Error, message: msg, code: code -> "Error #{code}: #{msg}"
end
```

### Fusion (Construction)

```elixir
result = fusion Result, response do
  {:ok, data} -> core Success, value: data
  {:error, reason} -> core Error, message: reason, code: 500
end
```

## Phase 1: Advanced Recursion

### Binary Tree with Asteroid Recursion (Eager)

```elixir
defstar BinaryTree do
  layers do
    core Empty
    core Leaf, value :: any()
    core Node,
      left :: asteroid(BinaryTree),
      right :: asteroid(BinaryTree),
      data :: any()
  end
end

# Build tree - all nodes computed immediately
tree = core(Node,
  left: asteroid(core(Leaf, value: 1)),
  right: asteroid(core(Leaf, value: 3)),
  data: 2
)

# Direct access (no function calls needed)
left_value = tree[:left][:value]  # => 1
```

### Lazy Stream with Rocket Recursion (Lazy)

```elixir
defstar LazyStream do
  layers do
    core Empty
    core Cons,
      head :: any(),
      tail :: rocket(LazyStream)
  end
end

# Build lazy stream - tail computed on demand
stream = core(Cons,
  head: 1,
  tail: rocket(fn ->
    core(Cons,
      head: 2,
      tail: rocket(fn -> core(Empty) end)
    )
  end)
)

# Launch rockets to access values
tail_stream = launch(stream[:tail])
second_value = tail_stream[:head]  # => 2
```

### Mixed Recursion Patterns

```elixir
defstar HybridTree do
  layers do
    core Empty
    core EagerNode,
      value :: any(),
      children :: list()  # Immediate computation
    core LazyNode,
      value :: any(),
      children :: rocket(list())  # Deferred computation
  end
end

# Eager node - children computed immediately
eager = core(EagerNode,
  value: "root",
  children: [
    asteroid(core(EagerNode, value: "child1", children: [])),
    asteroid(core(EagerNode, value: "child2", children: []))
  ]
)

# Lazy node - children computed on demand
lazy = core(LazyNode,
  value: "root",
  children: rocket(fn ->
    [core(LazyNode, value: "child1", children: rocket(fn -> [] end))]
  end)
)

# Access patterns
eager_children = eager[:children]           # Direct access
lazy_children = launch(lazy[:children])     # Launch required
```

## Type Safety Benefits

Stellarmorphism eliminates namespace collisions by requiring star-prefixed syntax:

```elixir
# Multiple stars can safely use same core names
defstar DatabaseResult do
  layers do
    core Success, rows :: list(), count :: integer()
    core Error, message :: String.t(), sql_code :: String.t()
  end
end

defstar HttpResult do
  layers do
    core Success, body :: String.t(), headers :: map()
    core Error, message :: String.t(), http_code :: integer()
  end
end

# Each star type is completely independent
db_result = core(Success, rows: data, count: 10)
http_result = core(Success, body: "response", headers: %{})

# Pattern matching with explicit star types
db_msg = fission DatabaseResult, db_result do
  core Success, rows: rows, count: count -> "Found #{count} rows"
  core Error, message: msg, sql_code: code -> "DB Error #{code}: #{msg}"
end

http_msg = fission HttpResult, http_result do
  core Success, body: body, headers: _headers -> "Response: #{body}"
  core Error, message: msg, http_code: code -> "HTTP Error #{code}: #{msg}"
end
```

## Parameterized Types & Constraints

```elixir
defstar BoundedList(max_size) when is_integer(max_size) and max_size > 0 do
  layers do
    core Empty, capacity :: integer()
    core Partial,
      items :: list(),
      count :: integer(),
      capacity :: integer()
    core Full,
      items :: list(),
      capacity :: integer()
  end
end

# Type constraint validation at construction
{:ok, small_list_type} = Types.apply_type_params(
  BoundedList,
  [{:max_size, quote(do: is_integer(max_size) and max_size > 0)}],
  [5]
)

{:error, _} = Types.apply_type_params(
  BoundedList,
  [{:max_size, quote(do: is_integer(max_size) and max_size > 0)}],
  [-1]  # Invalid: negative size
)
```

## Performance Characteristics

### Asteroid vs Rocket Trade-offs

**Asteroids (Eager Evaluation):**
- ✅ Higher memory usage upfront
- ✅ Faster access (no function calls)
- ✅ Immediate computation
- ❌ Not suitable for infinite structures

**Rockets (Lazy Evaluation):**
- ✅ Lower memory until launched
- ✅ Supports infinite/large structures
- ✅ Deferred expensive computations
- ❌ Slower access (requires function calls)

```elixir
# Asteroid: All computed immediately
eager_tree = core(Node,
  left: asteroid(expensive_computation()),
  right: asteroid(another_computation()),
  data: "root"
)

# Rocket: Computed only when needed
lazy_tree = core(Node,
  left: rocket(fn -> expensive_computation() end),
  right: rocket(fn -> another_computation() end),
  data: "root"
)

# Access patterns
eager_left = eager_tree[:left]           # Immediate
lazy_left = launch(lazy_tree[:left])     # Computed now
```

## Benchmarks

Stellarmorphism includes comprehensive performance benchmarks to help you understand the trade-offs between asteroid (eager) and rocket (lazy) recursion patterns. The benchmark suite tests everything from basic performance to concurrency scaling and real-world scenarios.

### Running Benchmarks

```bash
# Install dependencies first
mix deps.get

# Memory-safe benchmarks (recommended - prevents OOM)
mix run benchmarks/memory_safe_bench.ex

# Quick performance tests
mix run benchmarks/quick_bench.ex

# Run specific memory-safe tests
mix run benchmarks/memory_safe_bench.ex construction  # Safe construction test
mix run benchmarks/memory_safe_bench.ex memory       # Safe memory analysis
mix run benchmarks/memory_safe_bench.ex progressive  # Progressive scale test
mix run benchmarks/memory_safe_bench.ex limits       # Show safe limits

# Individual quick tests
mix run benchmarks/quick_bench.ex construction   # Construction performance
mix run benchmarks/quick_bench.ex access        # Access patterns
mix run benchmarks/quick_bench.ex traversal     # Tree traversal
mix run benchmarks/quick_bench.ex memory        # Memory usage
mix run benchmarks/quick_bench.ex comparison    # Direct comparison

# Simple test to verify everything works
mix run benchmarks/simple_benchmark.ex simple
```

The benchmark suite demonstrates key performance characteristics:

**Construction Performance**: Asteroids build structures immediately while rockets defer computation
**Access Patterns**: Direct asteroid access vs rocket launch() overhead
**Memory Usage**: Asteroids use more upfront memory, rockets scale better (⚠️ exponential growth at scale)
**Traversal Operations**: Full structure processing comparisons

**Memory Safety**: Binary trees grow exponentially (2^depth nodes). Use memory-safe benchmarks to prevent out-of-memory conditions.

### Benchmark Categories

#### 🔥 Asteroid vs Rocket Performance
Tests the fundamental performance differences between eager and lazy evaluation:

- **Construction Performance**: Time to build data structures
- **Access Patterns**: Direct access vs launch() overhead
- **Traversal Performance**: Full structure processing
- **Memory Usage**: Memory consumption patterns
- **Evaluation Strategies**: Partial vs full evaluation

#### ⚡ Concurrency Performance
Tests performance scaling from 1 to 32 processes:

- **Construction Concurrency**: Building structures in parallel
- **Traversal Concurrency**: Processing structures concurrently
- **Pattern Matching**: Concurrent fission operations
- **Mixed Workloads**: Real-world concurrent scenarios
- **Rocket Evaluation**: Lazy evaluation under concurrent load

#### 📈 Scale Performance
Tests performance as data structure sizes grow:

- **Tree Scaling**: Binary trees from depth 3 to 15
- **Stream Scaling**: Lazy streams from 10 to 10,000 elements
- **Memory Scaling**: Memory usage analysis at scale
- **Workload Scaling**: Batch operations from 100 to 5,000 items
- **Performance Degradation**: Analysis of scaling bottlenecks

#### 🏗️ Composite Real-World Scenarios
Tests realistic usage patterns:

- **JSON Processing**: Parsing and transforming nested JSON
- **Error Handling Pipelines**: Result types in processing chains
- **Data Transformation**: ETL-style workflows
- **Caching Simulation**: Lazy evaluation for cache systems
- **Parser Combinators**: Building and evaluating parse trees
- **Web API Simulation**: Request/response processing

### Performance Characteristics

The benchmarks reveal key performance trade-offs:

**Asteroid (Eager Evaluation):**
- ✅ Faster access (no function calls)
- ✅ Predictable memory usage
- ✅ Better for frequently accessed data
- ❌ Higher upfront memory cost
- ❌ Not suitable for infinite structures
- ❌ All computation done immediately

**Rocket (Lazy Evaluation):**
- ✅ Lower initial memory usage
- ✅ Supports infinite/large structures
- ✅ Computation only when needed
- ✅ Better for streaming scenarios
- ❌ Slower access (requires launch())
- ❌ Unpredictable evaluation timing

### Benchmark Results

Results are saved as HTML reports in `benchmarks/results/` with:
- Detailed performance metrics
- Memory usage analysis
- Concurrency scaling charts
- Performance comparisons
- System configuration details

### Performance Guidelines

Based on benchmark results:

1. **Use asteroids when**: You need frequent access, bounded data, predictable performance
2. **Use rockets when**: You have large/infinite data, infrequent access, streaming use cases
3. **Concurrency**: Optimal performance typically at 4-8 processes for CPU-bound tasks
4. **Memory**: Monitor usage carefully for deep structures (2^depth growth)
5. **Hybrid approaches**: Combine both patterns based on access patterns

## Utility Functions

### Deep Evaluation

```elixir
# Evaluate all nested rockets in a structure
nested_rockets = %{
  level1: rocket(fn ->
    %{level2: rocket(fn -> "deep_value" end)}
  end)
}

fully_evaluated = Recursion.deep_launch(nested_rockets)
# => %{level1: %{level2: "deep_value"}}
```

### Rocket Depth Analysis

```elixir
# Count nesting levels without evaluation
depth = Recursion.rocket_depth(nested_rockets)  # => 2
```

### Type Information

```elixir
# Check if a module uses parameterized types
Registry.is_parameterized?(MyBinaryTree)  # => true

# Get type parameters
params = Registry.get_type_params(MyBinaryTree)
# => [{:t, nil}]
```

## Migration & Compatibility

Phase 0 code continues to work unchanged. You can gradually adopt Phase 1 features:

```elixir
# Mix old and new approaches
mixed_structure = %{
  legacy_field: "old_style",
  eager_recursive: asteroid(%{data: "eager"}),
  lazy_recursive: rocket(fn -> %{data: "lazy"} end)
}
```

## API Reference

### Core Macros

- `defplanet/2` - Define product types with orbitals
- `defstar/2` - Define sum types with layers
- `fusion/3` - Type-safe construction with pattern matching
- `fission/3` - Type-safe pattern matching
- `core/1`, `core/2` - Construct star variants
- `asteroid/0`, `asteroid/1` - Eager recursion helpers
- `rocket/1` - Create lazy evaluation structures
- `launch/1` - Evaluate rocket structures

### Helper Modules

- `Stellarmorphism.Types` - Type parameter extraction and validation
- `Stellarmorphism.Recursion` - Asteroid/rocket utilities
- `Stellarmorphism.Constructors` - Enhanced constructor generation
- `Stellarmorphism.Registry` - Type registration and metadata

## Examples

### Real-world JSON Parser

```elixir
defstar JsonValue do
  layers do
    core Null
    core Bool, value :: boolean()
    core Number, value :: number()
    core String, value :: String.t()
    core Array, elements :: list()
    core Object, fields :: map()
  end
end

# Parse with pattern matching
parse_json = fn input ->
  fusion JsonValue, input do
    nil -> core(Null)
    bool when is_boolean(bool) -> core(Bool, value: bool)
    num when is_number(num) -> core(Number, value: num)
    str when is_binary(str) -> core(String, value: str)
    list when is_list(list) -> core(Array, elements: list)
    map when is_map(map) -> core(Object, fields: map)
  end
end

# Use with fission
stringify = fn json_value ->
  fission JsonValue, json_value do
    core Null -> "null"
    core Bool, value: true -> "true"
    core Bool, value: false -> "false"
    core Number, value: num -> to_string(num)
    core String, value: str -> "\"#{str}\""
    core Array, elements: elements -> "[#{Enum.join(elements, ", ")}]"
    core Object, fields: fields -> "{#{inspect(fields)}}"
  end
end
```

### Functional Data Structures

```elixir
# Persistent list with structural sharing
defstar PersistentList do
  layers do
    core Empty
    core Cons,
      head :: any(),
      tail :: asteroid(PersistentList)
  end
end

# Infinite sequence generator
defstar InfiniteSeq do
  layers do
    core Generator,
      current :: any(),
      next :: rocket(InfiniteSeq)
  end
end

# Fibonacci sequence
fibonacci = fn ->
  fib = fn a, b ->
    core(Generator,
      current: a,
      next: rocket(fn -> fib.(b, a + b) end)
    )
  end
  fib.(0, 1)
end

# Take first n elements
take = fn seq, n ->
  if n <= 0 do
    []
  else
    case seq do
      core(Generator, current: current, next: next_rocket) ->
        [current | take.(launch(next_rocket), n - 1)]
    end
  end
end

fibs = fibonacci.()
first_10 = take.(fibs, 10)  # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

## Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests to our GitHub repository.

## License

MIT License - see LICENSE file for details.
