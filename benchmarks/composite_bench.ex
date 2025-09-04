defmodule Stellarmorphism.CompositeBench do
  @moduledoc """
  Composite benchmarks testing real-world scenarios using Stellarmorphism.

  These benchmarks simulate realistic usage patterns combining multiple
  operations and data structures to test overall system performance.
  """

  alias Stellarmorphism.BenchmarkHelper
  import Stellarmorphism.DSL, only: [core: 1, core: 2, asteroid: 1, rocket: 1, launch: 1]

  def run_all_benchmarks do
    IO.puts("\n🏗️  Stellarmorphism: Composite Real-World Benchmarks")
    IO.puts("=" <> String.duplicate("=", 54))

    json_processing_benchmark()
    error_handling_pipeline_benchmark()
    data_transformation_benchmark()
    caching_simulation_benchmark()
    parser_combinator_benchmark()
    web_api_simulation_benchmark()
  end

  def json_processing_benchmark do
    # Simulate JSON processing with nested structures
    sample_json_data = generate_sample_json_data(100)

    BenchmarkHelper.run_benchmark(
      "JSON Processing Simulation",
      %{
        "parse_json_asteroid_trees" => fn ->
          Enum.map(sample_json_data, &parse_to_asteroid_structure/1)
        end,
        "parse_json_rocket_trees" => fn ->
          Enum.map(sample_json_data, &parse_to_rocket_structure/1)
        end,
        "validate_json_structures" => fn ->
          structures = Enum.map(sample_json_data, &parse_to_asteroid_structure/1)
          Enum.map(structures, &validate_json_structure/1)
        end,
        "transform_json_lazy" => fn ->
          structures = Enum.map(sample_json_data, &parse_to_rocket_structure/1)
          Enum.map(structures, &transform_json_lazy/1)
        end,
        "serialize_back_to_json" => fn ->
          structures = Enum.map(sample_json_data, &parse_to_asteroid_structure/1)
          Enum.map(structures, &serialize_json_structure/1)
        end
      },
      :standard
    )
  end

  def error_handling_pipeline_benchmark do
    # Simulate error handling pipelines with Result types
    operations = generate_operation_pipeline(200)

    BenchmarkHelper.run_benchmark(
      "Error Handling Pipeline Simulation",
      %{
        "sequential_error_handling" => fn ->
          Enum.reduce(operations, core(Success, value: 0), &apply_operation/2)
        end,
        "parallel_error_handling" => fn ->
          operations
          |> Enum.chunk_every(10)
          |> Task.async_stream(fn chunk ->
            Enum.reduce(chunk, core(Success, value: 0), &apply_operation/2)
          end)
          |> Enum.to_list()
        end,
        "error_recovery_pipeline" => fn ->
          Enum.reduce(operations, core(Success, value: 0), &apply_operation_with_recovery/2)
        end,
        "batch_validation" => fn ->
          Enum.map(operations, &validate_operation/1)
        end
      },
      :standard
    )
  end

  def data_transformation_benchmark do
    # Simulate data transformation workflows
    input_data = generate_transformation_data(500)

    BenchmarkHelper.run_benchmark(
      "Data Transformation Workflows",
      %{
        "eager_transformation_pipeline" => fn ->
          input_data
          |> Enum.map(&build_asteroid_pipeline/1)
          |> Enum.map(&execute_asteroid_pipeline/1)
        end,
        "lazy_transformation_pipeline" => fn ->
          input_data
          |> Enum.map(&build_rocket_pipeline/1)
          |> Enum.map(&execute_rocket_pipeline/1)
        end,
        "hybrid_transformation" => fn ->
          input_data
          |> Enum.map(&build_hybrid_pipeline/1)
          |> Enum.map(&execute_hybrid_pipeline/1)
        end,
        "streaming_transformation" => fn ->
          stream = build_transformation_stream(input_data)
          consume_transformation_stream(stream, 100)
        end
      },
      :standard
    )
  end

  def caching_simulation_benchmark do
    # Simulate caching scenarios with lazy evaluation
    cache_keys = 1..100 |> Enum.map(&"key_#{&1}")

    BenchmarkHelper.run_benchmark(
      "Caching Simulation",
      %{
        "eager_cache_population" => fn ->
          Map.new(cache_keys, fn key ->
            {key, compute_expensive_value(key)}
          end)
        end,
        "lazy_cache_with_rockets" => fn ->
          Map.new(cache_keys, fn key ->
            {key, rocket(fn -> compute_expensive_value(key) end)}
          end)
        end,
        "cache_access_pattern_random" => fn ->
          lazy_cache = Map.new(cache_keys, fn key ->
            {key, rocket(fn -> compute_expensive_value(key) end)}
          end)

          # Simulate random access pattern
          random_keys = Enum.take_random(cache_keys, 30)
          Enum.map(random_keys, fn key ->
            launch(lazy_cache[key])
          end)
        end,
        "cache_access_pattern_sequential" => fn ->
          lazy_cache = Map.new(cache_keys, fn key ->
            {key, rocket(fn -> compute_expensive_value(key) end)}
          end)

          # Simulate sequential access
          sequential_keys = Enum.take(cache_keys, 30)
          Enum.map(sequential_keys, fn key ->
            launch(lazy_cache[key])
          end)
        end
      },
      :standard
    )
  end

  def parser_combinator_benchmark do
    # Simulate parser combinator scenarios
    input_expressions = generate_parser_inputs(100)

    BenchmarkHelper.run_benchmark(
      "Parser Combinator Simulation",
      %{
        "parse_expressions_eager" => fn ->
          Enum.map(input_expressions, &parse_expression_eager/1)
        end,
        "parse_expressions_lazy" => fn ->
          Enum.map(input_expressions, &parse_expression_lazy/1)
        end,
        "evaluate_parse_trees" => fn ->
          trees = Enum.map(input_expressions, &parse_expression_eager/1)
          Enum.map(trees, &evaluate_expression_tree/1)
        end,
        "lazy_evaluate_on_demand" => fn ->
          lazy_trees = Enum.map(input_expressions, &parse_expression_lazy/1)
          # Only evaluate first 50
          lazy_trees
          |> Enum.take(50)
          |> Enum.map(&force_evaluate_lazy_tree/1)
        end
      },
      :standard
    )
  end

  def web_api_simulation_benchmark do
    # Simulate web API request/response scenarios
    api_requests = generate_api_requests(150)

    BenchmarkHelper.run_benchmark(
      "Web API Simulation",
      %{
        "process_api_requests_sync" => fn ->
          Enum.map(api_requests, &process_api_request_sync/1)
        end,
        "process_api_requests_async" => fn ->
          api_requests
          |> Task.async_stream(&process_api_request_async/1, max_concurrency: 8)
          |> Enum.to_list()
        end,
        "build_response_trees" => fn ->
          responses = Enum.map(api_requests, &process_api_request_sync/1)
          Enum.map(responses, &build_response_tree/1)
        end,
        "lazy_response_building" => fn ->
          Enum.map(api_requests, fn request ->
            rocket(fn ->
              response = process_api_request_sync(request)
              build_response_tree(response)
            end)
          end)
        end,
        "middleware_pipeline" => fn ->
          Enum.map(api_requests, &apply_middleware_pipeline/1)
        end
      },
      :standard
    )
  end

  # Helper functions for JSON processing

  defp generate_sample_json_data(count) do
    1..count |> Enum.map(fn i ->
      %{
        "id" => i,
        "name" => "item_#{i}",
        "data" => %{
          "value" => i * 10,
          "tags" => ["tag_#{rem(i, 5)}", "category_#{rem(i, 3)}"],
          "metadata" => %{
            "created_at" => "2024-01-#{rem(i, 28) + 1}",
            "score" => :rand.uniform(100)
          }
        },
        "children" => if rem(i, 3) == 0 do
          1..rem(i, 5) |> Enum.map(fn j -> %{"child_id" => "#{i}_#{j}", "value" => j} end)
        else
          []
        end
      }
    end)
  end

  defp parse_to_asteroid_structure(json_data) do
    core(Object,
      fields: %{
        id: asteroid(core(Number, value: json_data["id"])),
        name: asteroid(core(String, value: json_data["name"])),
        data: asteroid(parse_data_object(json_data["data"])),
        children: asteroid(parse_children_array(json_data["children"]))
      }
    )
  end

  defp parse_to_rocket_structure(json_data) do
    core(Object,
      fields: %{
        id: rocket(fn -> core(Number, value: json_data["id"]) end),
        name: rocket(fn -> core(String, value: json_data["name"]) end),
        data: rocket(fn -> parse_data_object(json_data["data"]) end),
        children: rocket(fn -> parse_children_array(json_data["children"]) end)
      }
    )
  end

  defp parse_data_object(data) do
    core(Object,
      fields: %{
        value: core(Number, value: data["value"]),
        tags: core(Array, elements: data["tags"]),
        metadata: core(Object, fields: data["metadata"])
      }
    )
  end

  defp parse_children_array(children) do
    core(Array, elements: children)
  end

  defp validate_json_structure(structure) do
    case structure do
      core(Object, fields: fields) ->
        Map.has_key?(fields, :id) && Map.has_key?(fields, :name)
      _ -> false
    end
  end

  defp transform_json_lazy(structure) do
    case structure do
      core(Object, fields: fields) ->
        id_value = launch(fields[:id])
        name_value = launch(fields[:name])
        %{transformed_id: id_value, transformed_name: name_value}
      _ -> %{}
    end
  end

  defp serialize_json_structure(structure) do
    case structure do
      core(Object, fields: _fields) -> "{\"serialized\": true}"
      _ -> "{}"
    end
  end

  # Helper functions for error handling

  defp generate_operation_pipeline(count) do
    1..count |> Enum.map(fn i ->
      operation_type = Enum.at([:add, :multiply, :divide, :subtract], rem(i, 4))
      value = rem(i, 20) + 1
      {operation_type, value}
    end)
  end

  defp apply_operation({operation, value}, result) do
    case result do
      core(Success, value: current) ->
        new_value = case operation do
          :add -> current + value
          :multiply -> current * value
          :divide when value != 0 -> div(current, value)
          :subtract -> current - value
          _ -> current
        end

        if new_value < 0 do
          core(Error, message: "Negative result", code: 400)
        else
          core(Success, value: new_value)
        end

      error -> error
    end
  end

  defp apply_operation_with_recovery({operation, value}, result) do
    case apply_operation({operation, value}, result) do
      core(Error, message: _, code: _) ->
        # Recovery: return to previous successful state
        result
      success -> success
    end
  end

  defp validate_operation({operation, value}) do
    valid_ops = [:add, :multiply, :divide, :subtract]

    if operation in valid_ops && is_integer(value) && value > 0 do
      core(Success, value: :valid)
    else
      core(Error, message: "Invalid operation", code: 422)
    end
  end

  # Helper functions for data transformation

  defp generate_transformation_data(count) do
    1..count |> Enum.map(fn i ->
      %{
        id: i,
        value: i * 2,
        category: rem(i, 5),
        metadata: %{score: :rand.uniform(100), priority: rem(i, 3)}
      }
    end)
  end

  defp build_asteroid_pipeline(data) do
    core(Node,
      left: asteroid(core(Leaf, value: data.id)),
      right: asteroid(core(Leaf, value: data.value)),
      data: data
    )
  end

  defp execute_asteroid_pipeline(pipeline) do
    case pipeline do
      core(Node, left: left, right: right, data: data) ->
        left_val = left[:value]
        right_val = right[:value]
        %{result: left_val + right_val, original: data}
      _ -> %{}
    end
  end

  defp build_rocket_pipeline(data) do
    core(Node,
      left: rocket(fn -> core(Leaf, value: data.id * 2) end),
      right: rocket(fn -> core(Leaf, value: data.value * 2) end),
      data: data
    )
  end

  defp execute_rocket_pipeline(pipeline) do
    case pipeline do
      core(Node, left: left_rocket, right: right_rocket, data: data) ->
        left = launch(left_rocket)
        right = launch(right_rocket)
        %{result: left[:value] + right[:value], original: data}
      _ -> %{}
    end
  end

  defp build_hybrid_pipeline(data) do
    core(EagerNode,
      value: data.id,
      children: [
        rocket(fn -> %{computed: data.value * 3} end),
        asteroid(%{immediate: data.category})
      ]
    )
  end

  defp execute_hybrid_pipeline(pipeline) do
    case pipeline do
      core(EagerNode, value: value, children: children) ->
        [lazy_child | [eager_child | _]] = children
        lazy_result = launch(lazy_child)
        %{
          base: value,
          lazy: lazy_result,
          eager: eager_child
        }
      _ -> %{}
    end
  end

  defp build_transformation_stream(data) do
    build_stream_from_list(data)
  end

  defp build_stream_from_list([]), do: core(Empty)
  defp build_stream_from_list([head | tail]) do
    core(Cons,
      head: transform_item(head),
      tail: rocket(fn -> build_stream_from_list(tail) end)
    )
  end

  defp transform_item(item) do
    %{
      transformed_id: item.id * 10,
      transformed_value: item.value + 100,
      category: item.category
    }
  end

  defp consume_transformation_stream(stream, count) do
    consume_stream(stream, count, [])
  end

  defp consume_stream(_, 0, acc), do: Enum.reverse(acc)
  defp consume_stream(core(Empty), _, acc), do: Enum.reverse(acc)
  defp consume_stream(core(Cons, head: head, tail: tail_rocket), count, acc) do
    tail = launch(tail_rocket)
    consume_stream(tail, count - 1, [head | acc])
  end

  # Helper functions for caching simulation

  defp compute_expensive_value(key) do
    # Simulate expensive computation
    hash = :erlang.phash2(key)
    result = Enum.reduce(1..100, hash, fn i, acc ->
      acc + i * hash
    end)
    %{key: key, computed_value: result, timestamp: :os.timestamp()}
  end

  # Helper functions for parser simulation

  defp generate_parser_inputs(count) do
    expressions = ["(+ 1 2)", "(* 3 4)", "(- 10 5)", "(/ 8 2)", "(+ (* 2 3) 4)"]
    1..count |> Enum.map(fn i ->
      Enum.at(expressions, rem(i, length(expressions)))
    end)
  end

  defp parse_expression_eager(expr) do
    # Simplified parser - just create a tree structure
    core(Node,
      left: asteroid(core(Leaf, value: :operator)),
      right: asteroid(core(Leaf, value: expr)),
      data: :parsed
    )
  end

  defp parse_expression_lazy(expr) do
    core(Node,
      left: rocket(fn -> core(Leaf, value: :operator) end),
      right: rocket(fn -> parse_complex_expression(expr) end),
      data: :parsed
    )
  end

  defp parse_complex_expression(expr) do
    # Simulate complex parsing
    tokens = String.split(expr, " ")
    core(Leaf, value: length(tokens))
  end

  defp evaluate_expression_tree(tree) do
    case tree do
      core(Node, left: left, right: right, data: _) ->
        left[:value] || right[:value] || 0
      _ -> 0
    end
  end

  defp force_evaluate_lazy_tree(tree) do
    case tree do
      core(Node, left: left_rocket, right: right_rocket, data: _) ->
        left = launch(left_rocket)
        right = launch(right_rocket)
        {left[:value], right[:value]}
      _ -> {0, 0}
    end
  end

  # Helper functions for web API simulation

  defp generate_api_requests(count) do
    1..count |> Enum.map(fn i ->
      %{
        id: i,
        method: Enum.at(["GET", "POST", "PUT", "DELETE"], rem(i, 4)),
        path: "/api/resource/#{i}",
        headers: %{"Authorization" => "Bearer token_#{i}"},
        body: (if rem(i, 2) == 0, do: %{data: "payload_#{i}"}, else: nil)
      }
    end)
  end

  defp process_api_request_sync(request) do
    # Simulate processing delay
    :timer.sleep(1)

    case request.method do
      "GET" -> core(Success, value: %{status: 200, data: "resource_#{request.id}"})
      "POST" -> core(Success, value: %{status: 201, data: "created_#{request.id}"})
      "PUT" -> core(Success, value: %{status: 200, data: "updated_#{request.id}"})
      "DELETE" ->
        if rem(request.id, 10) == 0 do
          core(Error, message: "Cannot delete", code: 403)
        else
          core(Success, value: %{status: 204, data: nil})
        end
    end
  end

  defp process_api_request_async(request) do
    # Simulate async processing
    Task.async(fn ->
      process_api_request_sync(request)
    end)
    |> Task.await()
  end

  defp build_response_tree(response) do
    case response do
      core(Success, value: data) ->
        core(Node,
          left: asteroid(core(Leaf, value: data.status)),
          right: asteroid(core(Leaf, value: data.data)),
          data: :success_response
        )
      core(Error, message: msg, code: code) ->
        core(Node,
          left: asteroid(core(Leaf, value: code)),
          right: asteroid(core(Leaf, value: msg)),
          data: :error_response
        )
    end
  end

  defp apply_middleware_pipeline(request) do
    request
    |> authenticate_middleware()
    |> authorize_middleware()
    |> validate_middleware()
    |> process_api_request_sync()
  end

  defp authenticate_middleware(request) do
    if Map.has_key?(request.headers, "Authorization") do
      request
    else
      %{request | headers: Map.put(request.headers, "Authorization", "Bearer default")}
    end
  end

  defp authorize_middleware(request) do
    # Simulate authorization check
    if request.method in ["GET", "POST"] do
      request
    else
      Map.put(request, :authorized, rem(request.id, 3) != 0)
    end
  end

  defp validate_middleware(request) do
    # Simulate validation
    if String.starts_with?(request.path, "/api/") do
      request
    else
      Map.put(request, :valid, false)
    end
  end

  # Individual benchmark runner

  def run_single_benchmark(benchmark_name) do
    case benchmark_name do
      "json" -> json_processing_benchmark()
      "error_handling" -> error_handling_pipeline_benchmark()
      "transformation" -> data_transformation_benchmark()
      "caching" -> caching_simulation_benchmark()
      "parser" -> parser_combinator_benchmark()
      "web_api" -> web_api_simulation_benchmark()
      _ ->
        IO.puts("Available benchmarks: json, error_handling, transformation, caching, parser, web_api")
        IO.puts("Or run all with: run_all_benchmarks()")
    end
  end
end
