defmodule ObservablesTest do
  use ExUnit.Case
  doctest Observables

  test "greets the world" do
    assert Observables.hello() == :world
  end
end
