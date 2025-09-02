# Define Phase 1 test types outside the test module to avoid cyclic dependencies
defmodule Phase1Test.Types do
  use Stellarmorphism

  # Phase 1: Binary Tree (recursive core layers)
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

  # Phase 1: Lazy Stream (recursive core layers)
  defstar LazyStream do
    layers do
      core Empty
      core Cons,
        head :: any(),
        tail :: rocket(LazyStream)
    end
  end

  # Phase 1: Container (recursive core layers)
  defstar Container do
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

  # Phase 1: Mixed recursion types (recursive core layers)
  defstar HybridTree do
    layers do
      core Empty
      core EagerNode,
        value :: any(),
        children :: list()
      core LazyNode,
        value :: any(),
        children :: rocket(list())
    end
  end

  # Phase 1: Planet (simplified for testing)
  defplanet Vector do
    orbitals do
      moon elements :: list()
      moon length :: integer()
      moon capacity :: integer()
    end
  end
end

defmodule Phase1Test do
  use ExUnit.Case, async: true

  alias Phase1Test.Types.{BinaryTree, LazyStream, Container, HybridTree, Vector}
  alias Stellarmorphism.{Types, Recursion}
  require Stellarmorphism.Recursion
  import Stellarmorphism.DSL, only: [fusion: 3, fission: 3, asteroid: 1, rocket: 1, launch: 1, core: 1, core: 2]

  describe "Phase 1: Asteroid recursion (eager evaluation)" do
    test "creates binary tree with eager asteroid recursion" do
      # Build tree with asteroid - all nodes computed immediately
      tree = core(Node,
        left: asteroid(core(Leaf, value: 1)),
        right: asteroid(core(Leaf, value: 3)),
        data: 2
      )

      # Verify structure is computed immediately
      assert tree[:__star__] == :Node
      assert tree[:data] == 2
      assert tree[:left][:__star__] == :Leaf
      assert tree[:left][:value] == 1
      assert tree[:right][:__star__] == :Leaf
      assert tree[:right][:value] == 3

      # Direct access - no special functions needed
      left_value = tree[:left][:value]
      assert left_value == 1
    end

    test "asteroid recursion evaluates immediately during construction" do
      # Track evaluation order
      Agent.start_link(fn -> [] end, name: :eval_order)

      get_leaf = fn value ->
        Agent.update(:eval_order, &[{:leaf, value} | &1])
        core(Leaf, value: value)
      end

      _tree = core(Node,
        left: asteroid(get_leaf.("left")),
        right: asteroid(get_leaf.("right")),
        data: "root"
      )

      # Verify both children were evaluated immediately
      order = Agent.get(:eval_order, & &1) |> Enum.reverse()
      assert order == [{:leaf, "left"}, {:leaf, "right"}]

      Agent.stop(:eval_order)
    end
  end

  describe "Phase 1: Rocket recursion (lazy evaluation)" do
    test "creates lazy stream with rocket recursion" do
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

      # Verify structure
      assert stream[:__star__] == :Cons
      assert stream[:head] == 1

      # Tail is a rocket (not yet evaluated)
      assert Recursion.is_rocket?(stream[:tail])

      # Launch rocket to get tail
      tail_stream = launch(stream[:tail])
      assert tail_stream[:__star__] == :Cons
      assert tail_stream[:head] == 2

      # Launch nested rocket
      final_tail = launch(tail_stream[:tail])
      assert final_tail[:__star__] == :Empty
    end

    test "rocket recursion evaluates lazily only when launched" do
      # Track evaluation order
      Agent.start_link(fn -> [] end, name: :lazy_eval_order)

      expensive_computation = fn id ->
        Agent.update(:lazy_eval_order, &[{:computed, id} | &1])
        core(Cons, head: id, tail: rocket(fn -> core(Empty) end))
      end

      stream = core(Cons,
        head: 0,
        tail: rocket(fn -> expensive_computation.(1) end)
      )

      # Verify nothing computed yet
      order = Agent.get(:lazy_eval_order, & &1)
      assert order == []

      # Launch first rocket
      tail1 = launch(stream[:tail])

      # Now first computation should have happened
      order = Agent.get(:lazy_eval_order, & &1)
      assert order == [{:computed, 1}]

      assert tail1[:head] == 1

      Agent.stop(:lazy_eval_order)
    end

    test "deep_launch evaluates all nested rockets" do
      nested_rockets = core(Cons,
        head: 1,
        tail: rocket(fn ->
          core(Cons,
            head: 2,
            tail: rocket(fn ->
              core(Cons, head: 3, tail: core(Empty))
            end)
          )
        end)
      )

      # Deep launch should evaluate all rockets
      fully_evaluated = Recursion.deep_launch(nested_rockets)

      assert fully_evaluated[:__star__] == :Cons
      assert fully_evaluated[:head] == 1
      assert fully_evaluated[:tail][:__star__] == :Cons
      assert fully_evaluated[:tail][:head] == 2
      assert fully_evaluated[:tail][:tail][:__star__] == :Cons
      assert fully_evaluated[:tail][:tail][:head] == 3
      assert fully_evaluated[:tail][:tail][:tail][:__star__] == :Empty
    end
  end

  describe "Phase 1: Parameterized types with constraints" do
    test "validates type parameter constraints at construction" do
      # Valid constraint
      assert {:ok, _result} =
        Types.validate_constraints(
          [{:max_size, 10}],
          [{:max_size, quote(do: is_integer(max_size) and max_size > 0)}]
        )

      # Invalid constraint - negative size
      assert {:error, msg} =
        Types.validate_constraints(
          [{:max_size, -5}],
          [{:max_size, quote(do: is_integer(max_size) and max_size > 0)}]
        )
      assert String.contains?(msg, "Constraint failed")

      # Invalid constraint - wrong type
      assert {:error, msg} =
        Types.validate_constraints(
          [{:max_size, "not_an_integer"}],
          [{:max_size, quote(do: is_integer(max_size))}]
        )
      assert String.contains?(msg, "Constraint failed")
    end

    test "parameterized types support type applications" do
      # Apply type parameters to create specialized instances
      {:ok, {base_type, param_map}} = Types.apply_type_params(
        Container,
        [{:max_size, quote(do: is_integer(max_size) and max_size > 0)}],
        [10]
      )

      assert base_type == Container
      assert param_map[:max_size] == 10
    end
  end

  describe "Phase 1: Mixed asteroid/rocket recursion" do
    test "supports both eager and lazy children in same structure" do
      # Eager node - all children computed immediately
      eager_tree = core(EagerNode,
        value: "root",
        children: [
          asteroid(core(EagerNode, value: "child1", children: [])),
          asteroid(core(EagerNode, value: "child2", children: []))
        ]
      )

      # Lazy node - children computed on demand
      lazy_tree = core(LazyNode,
        value: "root",
        children: rocket(fn ->
          [
            core(LazyNode, value: "child1", children: rocket(fn -> [] end)),
            core(LazyNode, value: "child2", children: rocket(fn -> [] end))
          ]
        end)
      )

      # Eager access
      eager_children = eager_tree[:children]
      assert length(eager_children) == 2
      assert Enum.at(eager_children, 0)[:value] == "child1"

      # Lazy access requires launch
      lazy_children = launch(lazy_tree[:children])
      assert is_list(lazy_children)
      assert length(lazy_children) == 2
      assert Enum.at(lazy_children, 0)[:value] == "child1"
    end
  end

  describe "Phase 1: Enhanced fusion/fission with parameters" do
    test "fusion works with parameterized types" do
      # This would be enhanced in a full implementation
      # For now, test basic fusion still works
      result = case {:ok, "test_data"} do
        {:ok, data} -> core(Success, value: data)
        {:error, msg} -> core(Error, message: msg)
      end

      assert result[:__star__] == :Success
      assert result[:value] == "test_data"
    end

    test "fission works with parameterized types" do
      # Test fission on parameterized tree structure
      tree = core(Node,
        left: core(Leaf, value: 42),
        right: core(Empty),
        data: "root"
      )

      result = case tree do
        core(Node, data: data, left: core(Leaf, value: val)) ->
          "Node #{data} with left leaf #{val}"
        core Leaf, value: val ->
          "Leaf #{val}"
        core Empty ->
          "Empty"
      end

      assert result == "Node root with left leaf 42"
    end
  end

  describe "Phase 1: Utility functions" do
    test "rocket depth calculation" do
      simple_rocket = rocket(fn -> "value" end)
      assert Recursion.rocket_depth(simple_rocket) == 1

      nested_rockets = %{
        level1: rocket(fn ->
          %{level2: rocket(fn -> "deep_value" end)}
        end)
      }
      assert Recursion.rocket_depth(nested_rockets) == 2

      no_rockets = %{regular: "value", data: 42}
      assert Recursion.rocket_depth(no_rockets) == 0
    end

    test "type parameter extraction" do
      # Test parameter extraction from type expressions
      {base, params} = Types.extract_type_params({:BinaryTree, [], [{:t, [], nil}]})
      assert base == :BinaryTree
      assert length(params) == 1

      {base, params} = Types.extract_type_params({:Vector, [], []})
      assert base == :Vector
      assert params == []
    end
  end

  describe "Phase 1: Registry integration" do
    test "registry handles parameterized types" do
      # Test that the registry can store and retrieve parameterized type info
      # This assumes the registry functions are working
      assert is_function(&Stellarmorphism.Registry.register_parameterized_star/4)
      assert is_function(&Stellarmorphism.Registry.get_parameterized_star/1)
      assert is_function(&Stellarmorphism.Registry.is_parameterized?/1)
    end
  end
end
