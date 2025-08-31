# Stellarmorphism Phase 1: Asteroids & Rockets 🪨🚀

## Overview

Phase 1 extends Stellarmorphism with two critical features for advanced algebraic data types:

1. **Asteroid Recursion** 🪨 - Eager/immediate recursive evaluation
2. **Rocket Recursion** 🚀 - Lazy/deferred recursive evaluation  
3. **Variable Arguments** - Pass runtime values to constructors

These features enable powerful recursive data structures while maintaining Stellarmorphism's stellar syntax and compile-time optimizations.

## Features

### 🪨 Asteroid: Eager Recursion

Asteroids represent **immediate computation** - recursive structures that are fully evaluated when created.

```elixir
defstar BinaryTree(t) do
  layers do
    core Empty
    core Leaf, value :: t
    core Node, 
      left :: asteroid(BinaryTree(t)),   # Computed immediately
      right :: asteroid(BinaryTree(t)),  # Full evaluation
      data :: t
  end
end

# Usage - everything computed eagerly
tree = core Node,
  left: asteroid(core Leaf, value: 1),
  right: asteroid(core Leaf, value: 3),
  data: 2

# Direct access - no special functions needed
left_value = tree.left.value  # Immediate access
```

### 🚀 Rocket: Lazy Recursion

Rockets represent **deferred computation** - recursive structures evaluated only when accessed via `launch()`.

```elixir
defstar InfiniteStream(t) do
  layers do
    core Empty
    core Cons, 
      head :: t,
      tail :: rocket(InfiniteStream(t))  # Lazy evaluation
  end
end

# Usage - tail computed on demand
stream = core Cons,
  head: 1,
  tail: rocket(fn -> 
    core Cons, head: 2, tail: rocket(fn -> next_stream() end)
  end)

# Launch rocket to access value
next_values = launch(stream.tail)  # Only computes when launched
```

### 🔧 Variable Arguments

Pass runtime values to constructors and recursive calls:

```elixir
defstar Counter(initial) when is_integer(initial) do
  layers do
    core Value, 
      current :: integer(),
      increment :: integer(), 
      default: initial
  end
end

# Variable-based construction
start_value = 10
counter = Counter.new(start_value, %{current: start_value, increment: 1})

# In recursive structures
defstar NumberedTree(t, start_num) do
  layers do
    core Empty
    core Node,
      value :: t,
      number :: integer(),
      left :: asteroid(NumberedTree(t, start_num + 1)),
      right :: asteroid(NumberedTree(t, start_num + 2))
  end
end

# Pass variables to recursive calls
tree = NumberedTree.build(42, %{
  value: "root",
  number: 42,
  left: asteroid(build_left_subtree(43)),
  right: asteroid(build_right_subtree(44))
})
```

## API Reference

### Core Macros

#### `asteroid(type_expr)`
Creates eagerly-evaluated recursive structure.

```elixir
asteroid(BinaryTree(integer()))
asteroid(JsonValue)
asteroid(List(User))
```

#### `rocket(lazy_expr)`
Creates lazily-evaluated recursive structure.

```elixir
rocket(fn -> build_infinite_sequence() end)
rocket(InfiniteStream(t))
rocket(fn -> expensive_computation() end)
```

#### `launch(rocket_value)`
Evaluates a rocket to get its value.

```elixir
stream = core Cons, head: 1, tail: rocket(fn -> next_values() end)
tail_stream = launch(stream.tail)
```

### Variable Arguments

#### Type Parameters with Constraints

```elixir
defstar Container(t, max_size) when is_integer(max_size) and max_size > 0 do
  layers do
    core Empty
    core Partial, items :: [t], size :: integer()
    core Full, items :: [t], size :: integer(), default: max_size
  end
end
```

#### Runtime Value Passing

```elixir
# Constructor with variables
Container.new(String, 10, %{items: ["a", "b"], size: 2})

# In fusion expressions
result = fusion Container, {items, max_capacity} do
  {items, cap} when length(items) < cap ->
    Container.new(String, cap, %{items: items, size: length(items)})
  
  {items, cap} ->
    Container.new(String, cap, %{items: Enum.take(items, cap), size: cap})
end
```

## Examples

### Binary Search Tree with Asteroids

```elixir
defmodule Trees do
  use Stellarmorphism
  
  defstar BST(t) do
    layers do
      core Empty
      core Node,
        value :: t,
        left :: asteroid(BST(t)),
        right :: asteroid(BST(t))
    end
  end
end

alias Trees.BST

# Build tree eagerly - all nodes computed immediately
tree = core Node,
  value: 5,
  left: asteroid(core Node,
    value: 3,
    left: asteroid(core Empty),
    right: asteroid(core Empty)
  ),
  right: asteroid(core Node,
    value: 8,
    left: asteroid(core Empty),
    right: asteroid(core Empty)
  )

# Insert function - eager evaluation
def insert_eager(tree, new_value) do
  fission Trees.BST, tree do
    core Empty ->
      core Node,
        value: new_value,
        left: asteroid(core Empty),
        right: asteroid(core Empty)
    
    core Node, value: v, left: l, right: r when new_value <= v ->
      core Node,
        value: v,
        left: asteroid(insert_eager(l, new_value)),  # Computed now
        right: asteroid(r)
    
    core Node, value: v, left: l, right: r ->
      core Node,
        value: v,
        left: asteroid(l),
        right: asteroid(insert_eager(r, new_value))  # Computed now
  end
end

# Usage
updated_tree = insert_eager(tree, 4)  # All changes computed immediately
```

### Infinite Stream with Rockets

```elixir
defmodule Streams do
  use Stellarmorphism
  
  defstar Stream(t) do
    layers do
      core Empty
      core Cons,
        head :: t,
        tail :: rocket(Stream(t))
    end
  end
end

alias Streams.Stream

# Infinite fibonacci sequence
def fibonacci() do
  fibonacci_from(0, 1)
end

defp fibonacci_from(a, b) do
  core Cons,
    head: a,
    tail: rocket(fn -> fibonacci_from(b, a + b) end)  # Lazy computation
end

# Take first n elements
def take(stream, n) when n <= 0, do: []

def take(stream, n) do
  fission Streams.Stream, stream do
    core Empty -> []
    core Cons, head: h, tail: lazy_tail ->
      [h | take(launch(lazy_tail), n - 1)]  # Launch when needed
  end
end

# Usage
fibs = fibonacci()
first_10 = take(fibs, 10)  # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
# Only computes the values actually needed!
```

### Mixed Asteroid/Rocket Tree

```elixir
defmodule MixedTrees do
  use Stellarmorphism
  
  defstar MixedTree(t) do
    layers do
      core Empty
      core EagerNode,
        value :: t,
        children :: [asteroid(MixedTree(t))]  # All children computed
      core LazyNode,
        value :: t,
        children :: rocket([MixedTree(t)])    # Children computed on access
    end
  end
end

# Eager node - all children computed immediately
eager_tree = core EagerNode,
  value: "root",
  children: [
    asteroid(core EagerNode, value: "child1", children: []),
    asteroid(core EagerNode, value: "child2", children: [])
  ]

# Lazy node - children computed on demand
lazy_tree = core LazyNode,
  value: "root",
  children: rocket(fn -> 
    [
      core LazyNode, value: "child1", children: rocket(fn -> [] end),
      core LazyNode, value: "child2", children: rocket(fn -> expensive_children() end)
    ]
  end)

# Access children
eager_children = eager_tree.children     # Direct access
lazy_children = launch(lazy_tree.children)  # Computed when launched
```

### Variable Arguments Example

```elixir
defmodule Containers do
  use Stellarmorphism
  
  defstar BoundedList(t, max_size) when is_integer(max_size) and max_size > 0 do
    layers do
      core Empty, capacity :: integer(), default: max_size
      core Partial, 
        items :: [t], 
        count :: integer(),
        capacity :: integer(), default: max_size
      core Full,
        items :: [t],
        capacity :: integer(), default: max_size
    end
  end
end

alias Containers.BoundedList

# Create with different capacities
small_list = BoundedList.new(String, 5, %{items: ["a", "b"], count: 2})
large_list = BoundedList.new(integer(), 1000, %{items: [1, 2, 3], count: 3})

# Functions using variables
def add_item(list, item, max_capacity) do
  fission Containers.BoundedList, list do
    core Empty, capacity: cap ->
      BoundedList.new(typeof(item), cap, %{items: [item], count: 1})
    
    core Partial, items: items, count: count, capacity: cap when count < cap ->
      core Full, items: [item | items], capacity: cap
      
    core Partial, items: items, count: count, capacity: cap ->
      core Partial, items: [item | items], count: count + 1, capacity: cap
      
    core Full, items: _, capacity: cap ->
      list  # Cannot add to full list
  end
end
```

## Implementation Notes

### Asteroid Implementation

```elixir
# Asteroids are evaluated immediately and stored directly
defmacro asteroid(expr) do
  quote do
    # Evaluate expression immediately when asteroid is created
    unquote(expr)
  end
end
```

### Rocket Implementation

```elixir
# Rockets store functions that are called when launched
defmacro rocket(expr) do
  quote do
    {:__rocket__, fn -> unquote(expr) end}
  end
end

defmacro launch(rocket_value) do
  quote do
    case unquote(rocket_value) do
      {:__rocket__, fun} -> fun.()
      other -> other  # Not a rocket, return as-is
    end
  end
end
```

### Variable Argument Implementation

```elixir
# Type parameters with constraints are checked at compile-time
defmacro defstar(name_with_params, do: block) when is_tuple(name_with_params) do
  # Extract name and parameters
  # Generate constructor functions that accept parameters
  # Validate constraints at runtime
end
```

## Performance Characteristics

### Asteroids (Eager)
- **Memory**: Higher - all structure computed upfront
- **Access Speed**: Fastest - direct field access
- **Creation Time**: Slower - all computation happens at construction
- **Best For**: Small to medium structures, frequent access patterns

### Rockets (Lazy)
- **Memory**: Lower - only computed portions stored  
- **Access Speed**: Slower - requires `launch()` call
- **Creation Time**: Faster - defers expensive computation
- **Best For**: Large structures, infrequent access, infinite sequences

## Migration Path

Phase 1 is fully backward compatible with existing Stellarmorphism code:

1. **Existing code continues to work** unchanged
2. **Add asteroid/rocket support** to existing types by updating layer definitions
3. **Gradual adoption** - mix eager and lazy as needed
4. **Performance optimization** by choosing appropriate recursion strategy

## Next Steps

Phase 1 establishes the foundation for:
- **Phase 2**: Protocols, generators, and Ecto integration
- **Phase 3**: Dependent types and advanced type-level programming  
- **Phase 4**: Distributed systems and serialization features

The asteroid/rocket system provides the recursive foundation that all future features will build upon!

---

**Stellarmorphism Phase 1**: Where recursive structures meet cosmic performance! 🪨🚀✨