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
end

defmodule StellarmorphismTest do
  use ExUnit.Case, async: true

  alias StellarmorphismTest.TestTypes.{User, Connection, Network, Result}
  import Stellarmorphism.DSL, only: [fusion: 2, fission: 2, asteroid: 0, asteroid: 1]

  describe "defplanet with moon orbitals" do
    test "creates struct with moon orbitals as fields" do
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

    test "works with multiple planet types with moon orbitals" do
      conn = Connection.new(%{from_id: 1, to_id: 2, strength: 0.8, created_at: ~D[2024-01-01]})

      assert %Connection{} = conn
      assert conn.from_id == 1
      assert conn.to_id == 2
      assert conn.strength == 0.8
      assert conn.created_at == ~D[2024-01-01]
    end
  end

  describe "defstar with layers/core" do
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

  describe "fusion with stellar constructors" do
    test "builds star core variants with elegant syntax" do
      user = User.new(%{id: 1, name: "Alice", score: 100})
      connections = [
        Connection.new(%{from_id: 1, to_id: 2, strength: 0.9}),
        Connection.new(%{from_id: 1, to_id: 3, strength: 0.7})
      ]

            network = fusion {user, connections} do
        {%User{score: score}, conns} when score > 50 and length(conns) > 1 ->
          core Connected, primary: user, connections: conns, metrics: %{avg_strength: 0.8}

        {%User{}, []} ->
          core Isolated, person: user, reason: "no_connections"

        {%User{}, conns} ->
          core Cluster, members: [user], center: user, radius: length(conns)
      end

      assert network[:__star__] == :Connected
      assert network[:primary] == user
      assert network[:connections] == connections
      assert network[:metrics][:avg_strength] == 0.8
    end

    test "works with simple value matching" do
      result = fusion :success do
        :success -> core Success, value: "operation completed"
        :error -> core Error, message: "operation failed", code: 500
      end

      assert result[:__star__] == :Success
      assert result[:value] == "operation completed"
    end
  end

  describe "fission with stellar patterns" do
    test "matches star core variants with elegant syntax" do
      user = User.new(%{id: 1, name: "Alice", score: 100})
      network = %{__star__: :Connected, primary: user, connections: [1, 2, 3], metrics: %{avg_strength: 0.8}}

            result = fission network do
        core Connected, primary: primary, connections: connections, metrics: _metrics ->
          "#{primary.name} has #{length(connections)} connections"

        core Isolated, person: person, reason: reason ->
          "#{person.name} is isolated: #{reason}"

        core Cluster, members: members, center: center, radius: _radius ->
          "Cluster of #{length(members)} centered on #{center.name}"
      end

      assert result == "Alice has 3 connections"
    end

    test "matches planets (structs) directly" do
      user = User.new(%{id: 1, name: "Bob", email: "bob@test.com", score: 75})

      greeting = fission user do
        %User{name: name, score: score} when score > 50 ->
          "Hello, high-scorer #{name}!"

        %User{name: name} ->
          "Hello, #{name}!"
      end

      assert greeting == "Hello, high-scorer Bob!"
    end

    test "works with nested patterns" do
      result_success = %{__star__: :Success, value: %{data: "important info"}}
      result_error = %{__star__: :Error, message: "not found", code: 404}

      success_msg = fission result_success do
        core Success, value: %{data: data} -> "Got: #{data}"
        core Error, message: _message, code: code -> "Error #{code}"
      end

      error_msg = fission result_error do
        core Success, value: %{data: data} -> "Got: #{data}"
        core Error, message: _message, code: code -> "Error #{code}"
      end

      assert success_msg == "Got: important info"
      assert error_msg == "Error 404"
    end
  end

  describe "asteroid" do
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

  describe "integration" do
    test "full workflow with planets, stars, fusion, and fission" do
      # Create some users
      alice = User.new(%{id: 1, name: "Alice", email: "alice@test.com", score: 95})
      bob = User.new(%{id: 2, name: "Bob", email: "bob@test.com", score: 30})

      # Create connections
      connections = [
        Connection.new(%{from_id: 1, to_id: 2, strength: 0.8}),
        Connection.new(%{from_id: 1, to_id: 3, strength: 0.6})
      ]

            # Use fusion to build network based on user score and connections
      network = fusion {alice, connections} do
        {%User{score: score}, conns} when score > 80 ->
          core Connected, primary: alice, connections: conns, metrics: %{type: "influencer"}

        {%User{score: score}, conns} when score > 50 ->
          core Connected, primary: alice, connections: conns, metrics: %{type: "regular"}

        {user, []} ->
          core Isolated, person: user, reason: "no_connections"
      end

      # Use fission to analyze the network
      analysis = fission network do
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

      # Generate tracking ID
      {:asteroid, tracking_name, tracking_id} = asteroid()
      assert is_atom(tracking_name)
      assert is_binary(tracking_id)
    end
  end
end
