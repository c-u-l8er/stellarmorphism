# Stellarmorphism 🌟

A stellar-themed, high-performance Algebraic Data Type DSL for Elixir with beautiful mathematical syntax and compile-time optimizations.

[![Build Status](https://github.com/your-org/stellarmorphism/workflows/CI/badge.svg)](https://github.com/your-org/stellarmorphism/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/stellarmorphism.svg)](https://hex.pm/packages/stellarmorphism)
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/stellarmorphism)

## ✨ Features

- **🪐 `defplanet`**: Define product types with `moon` orbitals (structs)
- **⭐ `defstar`**: Define sum types with `layers` and `core` variants (unions)
- **💥 `fission`**: Elegant pattern matching over planets and stars
- **⚡ `fusion`**: Elegant constructors with stellar syntax
- **☄️ `asteroid`**: Generate unique recursive/identifier tuples
- **🚀 Compile-time optimizations** with AST transformation
- **🔧 Full Elixir integration** with proper module resolution

## 📦 Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:stellarmorphism, "~> 0.1.0"}
  ]
end
```

For development, you can use a local path:

```elixir
{:stellarmorphism, path: "./stellarmorphism"}
```

## 🚀 Quick Start

```elixir
defmodule Space.Types do
  use Stellarmorphism

  # Define planets with moon orbitals
  defplanet User do
    orbitals do
      moon id :: String.t()
      moon name :: String.t()
      moon email :: String.t()
      moon score :: integer()
    end
  end

  defplanet Connection do
    orbitals do
      moon from_id :: integer()
      moon to_id :: integer()
      moon strength :: float()
      moon created_at
    end
  end

  # Define stars with layers and core variants
  defstar Network do
    layers do
      core Connected,
        primary :: User.t(),
        connections :: [Connection.t()],
        metrics :: map()
      core Isolated,
        person :: User.t(),
        reason :: String.t()
      core Cluster,
        members :: [User.t()],
        center :: User.t(),
        radius :: integer()
    end
  end

  defstar Result do
    layers do
      core Success,
        value :: any()
      core Error,
        message :: String.t(),
        code :: integer()
    end
  end
end

alias Space.Types.{User, Connection, Network, Result}

# Create planets (structs)
user = User.new(%{id: "u1", name: "Alice", email: "alice@stellar.com", score: 95})
connections = [
  Connection.new(%{from_id: 1, to_id: 2, strength: 0.8}),
  Connection.new(%{from_id: 1, to_id: 3, strength: 0.6})
]

# Fusion (elegant constructors)
network = fusion Space.Types.Network, {user, connections} do
  {%User{score: score}, conns} when score > 80 ->
    core Connected, primary: user, connections: conns, metrics: %{type: "influencer"}
  
  {%User{score: score}, conns} when score > 50 ->
    core Connected, primary: user, connections: conns, metrics: %{type: "regular"}
  
  {user, []} ->
    core Isolated, person: user, reason: "no_connections"
end

# Fission (elegant pattern matching)
analysis = fission Space.Types.Network, network do
  core Connected, primary: %User{name: name, score: score}, connections: conns, metrics: %{type: type} ->
    %{
      user: name,
      score: score,
      connection_count: length(conns),
      user_type: type,
      status: "connected"
    }
  
  core Isolated, person: %User{name: name}, reason: reason ->
    %{
      user: name,
      status: "isolated",
      reason: reason
    }
end

# Generate tracking asteroids
{:asteroid, tracking_name, tracking_id} = asteroid()
```

## 🌟 Stellar Syntax Features

### Moon Orbitals (Product Types)

Beautiful field definitions with stellar naming and type annotations:

```elixir
defplanet Spacecraft do
  orbitals do
    moon id :: String.t()
    moon fuel_level :: float()
    moon coordinates :: {float(), float(), float()}
    moon status :: atom()
    moon crew_size :: integer()
  end
end

# Creates a struct with fields: id, fuel_level, coordinates, status, crew_size
spacecraft = Spacecraft.new(%{
  id: "voyager-1",
  fuel_level: 0.85,
  coordinates: {1.2, 3.4, 5.6},
  status: :active,
  crew_size: 0
})
```

### Core Layers (Sum Types)

Elegant sum type variants with multiple syntax styles:

```elixir
defstar Mission do
  layers do
    core Planning,
      objectives :: [String.t()],
      timeline :: DateTime.t(),
      resources :: map()
    core InProgress,
      current_phase :: String.t(),
      progress :: float(),
      team :: [User.t()]
    core Completed,
      results :: map(),
      duration :: integer(),
      lessons_learned :: [String.t()]
    core Aborted,
      reason :: String.t(),
      recovery_plan :: String.t(),
      cost :: float()
  end
end

defstar WeightedGraph do
  layers do
    core EmptyGraph
    core SingleNode,
      node :: GraphNode.t()
    core ConnectedGraph,
      nodes :: [GraphNode.t()],
      edges :: [GraphEdge.t()],
      topology_type :: atom()
    core HierarchicalGraph,
      root :: GraphNode.t(),
      children :: [asteroid(WeightedGraph)],
      hierarchy_type :: atom()
  end
end
```

### Stellar Pattern Matching

#### Fission (Pattern Matching)

```elixir
mission_status = fission Mission, mission do
  core Planning, objectives: objectives, timeline: timeline, resources: _resources ->
    "Planning #{length(objectives)} objectives over #{timeline}"
  
  core InProgress, current_phase: phase, progress: progress, team: team ->
    "Currently in #{phase}, #{progress}% complete with #{length(team)} team members"
  
  core Completed, results: results, duration: duration, lessons_learned: lessons ->
    "Mission completed in #{duration} with #{inspect(results)}. Lessons: #{length(lessons)}"
  
  core Aborted, reason: reason, recovery_plan: recovery, cost: cost ->
    "Mission aborted: #{reason}. Recovery: #{recovery}. Cost: $#{cost}"
end

# Match on planets (structs) directly
user_info = fission Space.Types.User, user do
  %User{score: score, name: name} when score > 90 ->
    "#{name} is a stellar performer!"
  
  %User{score: score, name: name} when score > 70 ->
    "#{name} is doing well"
  
  %User{name: name} ->
    "#{name} needs support"
end
```

#### Fusion (Construction)

```elixir
# Fusion with core syntax
result = fusion Space.Types.Result input_data do
  {:success, data} ->
    core Success, value: data
    
  {:error, msg, code} ->
    core Error, message: msg, code: code
end

# Complex fusion with guards and patterns
network_state = fusion Space.Types.Network, {user, connections, metrics} do
  {%User{score: score}, conns, %{type: type}} when score > 80 and type == "premium" ->
    core Connected, 
      primary: user, 
      connections: conns, 
      metrics: Map.put(metrics, :status, "premium_connected")
  
  {%User{score: score}, conns, _metrics} when score > 50 ->
    core Connected, 
      primary: user, 
      connections: conns, 
      metrics: Map.put(metrics, :status, "standard_connected")
  
  {user, [], _metrics} ->
    core Isolated, 
      person: user, 
      reason: "no_connections"
  
  {user, conns, metrics} ->
    core Cluster, 
      members: [user], 
      center: user, 
      radius: length(conns)
end
```

### Asteroid Generation

Generate unique identifiers for tracking and recursion:

```elixir
# Generate with random name
{:asteroid, name, id} = asteroid()
# => {:asteroid, :a_1a2b3c4d5e6f7g8, "1a2b3c4d5e6f7g8"}

# Generate with custom name
{:asteroid, :mission_tracker, id} = asteroid(:mission_tracker)
# => {:asteroid, :mission_tracker, "9h0i1j2k3l4m5n6o"}

# Use in recursive structures
defstar RecursiveTree do
  layers do
    core Leaf,
      value :: any()
    core Node,
      left :: asteroid(RecursiveTree),
      right :: asteroid(RecursiveTree),
      data :: any()
  end
end
```

## 🔧 Advanced Usage

### Module Resolution

Stellarmorphism automatically handles module resolution relative to the caller:

```elixir
defmodule MyApp.Types do
  use Stellarmorphism
  
  # This creates MyApp.Types.User, not just User
  defplanet User do
    orbitals do
      moon name :: String.t()
    end
  end
end

# Access as MyApp.Types.User
user = MyApp.Types.User.new(%{name: "Alice"})
```

### Type Annotations

Type annotations in core definitions provide documentation and future type checking support:

```elixir
defstar ApiResponse do
  layers do
    core Success,
      data :: map(),
      timestamp :: DateTime.t(),
      version :: String.t()
    core Error,
      message :: String.t(),
      code :: integer(),
      details :: map() | nil
    core Pending,
      request_id :: String.t(),
      estimated_time :: integer()
  end
end
```

### Compile-time Optimizations

All stellar syntax transforms at compile-time to efficient Elixir code:

```elixir
# This:
core Connected, primary: user, connections: conns

# Becomes this at compile-time:
%{__star__: :Connected, primary: user, connections: conns}
```

## 🧪 Testing

Run the test suite to see all features in action:

```bash
mix test
```

The test suite covers:
- Planet (struct) creation and orbital access
- Star variant metadata and registration
- Fusion construction with complex patterns
- Fission pattern matching on all types
- Asteroid generation and uniqueness
- Full integration workflows

## 📚 API Reference

### Macros

- `defplanet(name, do: block)` - Define a product type with moon orbitals
- `defstar(name, do: block)` - Define a sum type with core layers
- `fusion(seed, do: clauses)` - Elegant construction with core syntax
- `fission(value, do: clauses)` - Elegant pattern matching with core syntax
- `asteroid(name \\ nil)` - Generate unique identifiers

### Helper Macros

- `orbitals(do: block)` - Define moon orbitals for planets
- `layers(do: block)` - Define core layers for stars
- `moon(name, type \\ nil)` - Define a moon orbital
- `core(name, field_specs)` - Define a core variant

## 🎯 Use Cases

- **API Response Handling**: Clean sum types for success/error states
- **State Machines**: Elegant state transitions with fusion/fission
- **Data Validation**: Structured error handling with detailed variants
- **Configuration Management**: Type-safe configuration with stellar syntax
- **Recursive Data Structures**: Trees, graphs, and nested hierarchies
- **Event Processing**: Pattern matching on complex event structures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🌟 Acknowledgments

Inspired by the mathematical elegance of algebraic data types and the beauty of stellar phenomena. Built with ❤️ for the Elixir community.

---

**Stellarmorphism**: Where functional programming meets the cosmos! 🚀✨


