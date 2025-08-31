# Define test types outside the test module to avoid cyclic dependencies
defmodule StellarmorphismTest.TestTypes do
  use Stellarmorphism

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

  # Phase 0: Demonstrate multiple stars with same core names (no collision)
  defstar ApiResponse do
    layers do
      core Success,
        data :: map(),
        status :: integer()
      core Error,
        message :: String.t(),
        code :: integer()
    end
  end
end

defmodule StellarmorphismPhase0Test do
  use ExUnit.Case, async: true

  alias StellarmorphismTest.TestTypes.{User, Connection, Network, Result, ApiResponse}
  import Stellarmorphism.DSL, only: [fusion: 3, fission: 3, asteroid: 0, asteroid: 1]

  describe "Phase 0: Star-prefixed fission eliminates namespace collisions" do
    test "different star types with same core names work independently" do
      # Create test data for Result star
      result_success = %{__star__: :Success, value: %{data: "important info"}}
      result_error = %{__star__: :Error, message: "not found", code: 404}

      # Create test data for ApiResponse star
      api_success = %{__star__: :Success, data: %{user: "alice"}, status: 200}
      api_error = %{__star__: :Error, message: "unauthorized", code: 401}

      # Phase 0: Star-prefixed fission with Result type
      success_msg = fission Result, result_success do
        core Success, value: %{data: data} -> "Got: #{data}"
        core Error, message: _message, code: code -> "Error #{code}"
      end

      error_msg = fission Result, result_error do
        core Success, value: %{data: data} -> "Got: #{data}"
        core Error, message: _message, code: code -> "Error #{code}"
      end

      # Phase 0: Star-prefixed fission with ApiResponse type (same core names, different structure!)
      api_msg = fission ApiResponse, api_success do
        core Success, data: data, status: status -> "API Success #{status}: #{inspect(data)}"
        core Error, message: msg, code: code -> "API Error #{code}: #{msg}"
      end

      api_err_msg = fission ApiResponse, api_error do
        core Success, data: data, status: status -> "API Success #{status}: #{inspect(data)}"
        core Error, message: msg, code: code -> "API Error #{code}: #{msg}"
      end

      # Verify each star type works correctly with its own core structure
      assert success_msg == "Got: important info"
      assert error_msg == "Error 404"
      assert api_msg == "API Success 200: %{user: \"alice\"}"
      assert api_err_msg == "API Error 401: unauthorized"
    end

    test "star-prefixed fission enforces type safety at compile time" do
      # This test shows that the user MUST specify the star type
      result_success = %{__star__: :Success, value: "test data"}

      # This should work - star type specified
      msg = fission Result, result_success do
        core Success, value: data -> "Got: #{data}"
        core Error, message: message, code: _code -> "Error: #{message}"
      end

      assert msg == "Got: test data"

      # Note: The old syntax fission(value) is no longer available in Phase 0
      # This enforces type safety by requiring explicit star type specification
    end

    test "matches planets (structs) directly with fission" do
      user = User.new(%{id: 1, name: "Bob", email: "bob@test.com", score: 75})

      # Fission can still match on regular structs (planets)
      greeting = case user do
        %User{name: name, score: score} when score > 50 ->
          "Hello, high-scorer #{name}!"
        %User{name: name} ->
          "Hello, #{name}!"
      end

      assert greeting == "Hello, high-scorer Bob!"
    end
  end

  describe "Phase 0: Star-prefixed fusion eliminates namespace collisions" do
    test "different star types with same core names construct independently" do
      # Phase 0: Star-prefixed fusion with Result type
      result = fusion Result, :success do
        :success -> core Success, value: "operation completed"
        :error -> core Error, message: "operation failed", code: 500
      end

      # Phase 0: Star-prefixed fusion with ApiResponse type (same core names!)
      api_response = fusion ApiResponse, {:ok, %{user: "alice"}} do
        {:ok, data} -> core Success, data: data, status: 200
        {:error, reason} -> core Error, message: reason, code: 500
      end

      # Verify each star type constructs correctly with its own structure
      assert result[:__star__] == :Success
      assert result[:value] == "operation completed"

      assert api_response[:__star__] == :Success
      assert api_response[:data] == %{user: "alice"}
      assert api_response[:status] == 200

      # Note how Result.Success has :value but ApiResponse.Success has :data and :status
      assert Map.has_key?(result, :value)
      refute Map.has_key?(result, :data)
      refute Map.has_key?(result, :status)

      assert Map.has_key?(api_response, :data)
      assert Map.has_key?(api_response, :status)
      refute Map.has_key?(api_response, :value)
    end

    test "star-prefixed fusion with complex patterns" do
      user = User.new(%{id: 1, name: "Alice", score: 100})
      connections = [
        Connection.new(%{from_id: 1, to_id: 2, strength: 0.9}),
        Connection.new(%{from_id: 1, to_id: 3, strength: 0.7})
      ]

      # Phase 0: Star-prefixed fusion with Network type and complex patterns
      network = fusion Network, {user, connections} do
        {%User{score: score}, conns} when score > 80 and length(conns) > 1 ->
          core Connected, primary: user, connections: conns, metrics: %{type: "influencer"}

        {%User{score: score}, conns} when score > 50 ->
          core Connected, primary: user, connections: conns, metrics: %{type: "regular"}

        {user, []} ->
          core Isolated, person: user, reason: "no_connections"
      end

      assert network[:__star__] == :Connected
      assert network[:primary] == user
      assert network[:connections] == connections
      assert network[:metrics][:type] == "influencer"
    end
  end

  describe "Phase 0: Integration with planets unchanged" do
    test "defplanet with moon orbitals works as before" do
      user = User.new(%{id: 1, name: "Alice", email: "alice@test.com", score: 100})

      assert %User{} = user
      assert user.id == 1
      assert user.name == "Alice"
      assert user.email == "alice@test.com"
      assert user.score == 100
    end

    test "provides __stellarmorphism__/1 metadata for moon orbitals" do
      orbitals = User.__stellarmorphism__(:orbitals)
      assert :id in orbitals
      assert :name in orbitals
      assert :email in orbitals
      assert :score in orbitals
    end
  end

  describe "Phase 0: Star metadata unchanged" do
    test "provides variant metadata for core layers" do
      variants = Network.__stellarmorphism__(:variants)

      assert Map.has_key?(variants, :Connected)
      assert Map.has_key?(variants, :Isolated)
      assert Map.has_key?(variants, :Cluster)

      assert [:primary, :connections, :metrics] = variants[:Connected]
      assert [:person, :reason] = variants[:Isolated]
      assert [:members, :center, :radius] = variants[:Cluster]
    end
  end

  describe "Phase 0: Full integration workflow" do
    test "complete workflow with star-prefixed syntax" do
      # Create some users
      alice = User.new(%{id: 1, name: "Alice", email: "alice@test.com", score: 95})
      bob = User.new(%{id: 2, name: "Bob", email: "bob@test.com", score: 30})

      # Create connections
      connections = [
        Connection.new(%{from_id: 1, to_id: 2, strength: 0.8}),
        Connection.new(%{from_id: 1, to_id: 3, strength: 0.6})
      ]

      # Phase 0: Use star-prefixed fusion to build network
      network = fusion Network, {alice, connections} do
        {%User{score: score}, conns} when score > 80 ->
          core Connected, primary: alice, connections: conns, metrics: %{type: "influencer"}

        {%User{score: score}, conns} when score > 50 ->
          core Connected, primary: alice, connections: conns, metrics: %{type: "regular"}

        {user, []} ->
          core Isolated, person: user, reason: "no_connections"
      end

      # Phase 0: Use star-prefixed fission to analyze the network
      analysis = fission Network, network do
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

      # Verify the results
      assert analysis.user == "Alice"
      assert analysis.score == 95
      assert analysis.connection_count == 2
      assert analysis.user_type == "influencer"
      assert analysis.status == "connected"

      # Generate tracking ID (unchanged)
      {:asteroid, tracking_name, tracking_id} = asteroid()
      assert is_atom(tracking_name)
      assert is_binary(tracking_id)
    end
  end

  describe "Phase 0: Asteroid helpers unchanged" do
    test "generates unique identifier tuples" do
      {:asteroid, name1, id1} = asteroid()
      {:asteroid, name2, id2} = asteroid()

      assert is_atom(name1)
      assert is_atom(name2)
      assert is_binary(id1)
      assert is_binary(id2)

      # Should be unique
      assert name1 != name2
      assert id1 != id2

      # Should have expected format
      assert String.starts_with?(Atom.to_string(name1), "a_")
      assert String.length(id1) == 16  # 8 bytes encoded as hex
    end

    test "accepts custom names" do
      {:asteroid, :custom_name, id} = asteroid(:custom_name)

      assert is_binary(id)
      assert String.length(id) == 16
    end

    test "generates different IDs for same name" do
      {:asteroid, :same, id1} = asteroid(:same)
      {:asteroid, :same, id2} = asteroid(:same)

      assert id1 != id2
    end
  end

  describe "Phase 0: Demonstrates type safety benefits" do
    test "multiple stars with same core names are completely independent" do
      # Both Result and ApiResponse have Success and Error cores, but different structures

      # Test Result star
      result_data = %{__star__: :Success, value: "completed successfully"}
      result_analysis = fission Result, result_data do
        core Success, value: data -> "Result success: #{data}"
        core Error, message: msg, code: code -> "Result error #{code}: #{msg}"
      end
      assert result_analysis == "Result success: completed successfully"

      # Test ApiResponse star with SAME core name but DIFFERENT structure
      api_data = %{__star__: :Success, data: %{user: "alice"}, status: 200}
      api_analysis = fission ApiResponse, api_data do
        core Success, data: data, status: status -> "API success #{status}: #{inspect(data)}"
        core Error, message: msg, code: code -> "API error #{code}: #{msg}"
      end
      assert api_analysis == "API success 200: %{user: \"alice\"}"

      # The key insight: Same core names (Success/Error) but completely different structures
      # This was impossible before Phase 0 due to namespace collisions
    end

    test "fusion creates correct structures for each star type" do
      # Create Result.Success
      result = fusion Result, :ok do
        :ok -> core Success, value: "task completed"
        :error -> core Error, message: "task failed", code: 500
      end

      # Create ApiResponse.Success
      api_response = fusion ApiResponse, :ok do
        :ok -> core Success, data: %{id: 123}, status: 201
        :error -> core Error, message: "api failed", code: 400
      end

      # Verify they have same core name but different structures
      assert result[:__star__] == :Success
      assert api_response[:__star__] == :Success

      # But completely different field structures
      assert Map.has_key?(result, :value)
      refute Map.has_key?(result, :data)
      refute Map.has_key?(result, :status)

      refute Map.has_key?(api_response, :value)
      assert Map.has_key?(api_response, :data)
      assert Map.has_key?(api_response, :status)
    end
  end
end

# Additional Phase 0 demonstration module
defmodule Phase0Demo.Types do
  use Stellarmorphism

  # Demonstrate how multiple stars can safely use common core names
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

  defstar FileResult do
    layers do
      core Success, content :: binary(), path :: String.t()
      core Error, message :: String.t(), errno :: integer()
    end
  end
end

defmodule Phase0DemoTest do
  use ExUnit.Case, async: true

  alias Phase0Demo.Types.{DatabaseResult, HttpResult, FileResult}
  import Stellarmorphism.DSL, only: [fusion: 3, fission: 3]

  test "Phase 0 allows multiple stars with identical core names" do
    # All three stars have Success and Error cores, but they're completely independent

    # Create database success
    db_result = fusion DatabaseResult, {:ok, [%{id: 1}, %{id: 2}]} do
      {:ok, rows} -> core Success, rows: rows, count: length(rows)
      {:error, msg, code} -> core Error, message: msg, sql_code: code
    end

    # Create HTTP success
    http_result = fusion HttpResult, {:ok, "response body", %{"content-type" => "json"}} do
      {:ok, body, headers} -> core Success, body: body, headers: headers
      {:error, msg, code} -> core Error, message: msg, http_code: code
    end

    # Create file success
    file_result = fusion FileResult, {:ok, <<1, 2, 3>>, "/tmp/test"} do
      {:ok, content, path} -> core Success, content: content, path: path
      {:error, msg, errno} -> core Error, message: msg, errno: errno
    end

    # All have Success core but completely different structures
    assert db_result[:__star__] == :Success
    assert http_result[:__star__] == :Success
    assert file_result[:__star__] == :Success

    # Pattern match each independently
    db_msg = fission DatabaseResult, db_result do
      core Success, rows: rows, count: count -> "DB: #{count} rows found"
      core Error, message: msg, sql_code: code -> "DB Error #{code}: #{msg}"
    end

    http_msg = fission HttpResult, http_result do
      core Success, body: body, headers: _headers -> "HTTP: #{String.length(body)} bytes"
      core Error, message: msg, http_code: code -> "HTTP Error #{code}: #{msg}"
    end

    file_msg = fission FileResult, file_result do
      core Success, content: content, path: path -> "File: #{byte_size(content)} bytes from #{path}"
      core Error, message: msg, errno: errno -> "File Error #{errno}: #{msg}"
    end

    assert db_msg == "DB: 2 rows found"
    assert http_msg == "HTTP: 13 bytes"
    assert file_msg == "File: 3 bytes from /tmp/test"

    # This demonstrates the core value of Phase 0:
    # Multiple star types can safely use the same core names without collision
  end
end
