defmodule SimpleTest.TestUser do
  defstruct [:id, :name, :score]
end

defmodule SimpleTest do
  use ExUnit.Case

  alias SimpleTest.TestUser

  test "basic struct creation" do
    # Test without using the DSL macros first
    user = %TestUser{id: 1, name: "Alice", score: 10}
    assert user.id == 1
    assert user.name == "Alice"
    assert user.score == 10
  end
end
