defmodule TonyTest do
  use ExUnit.Case
  doctest Tony

  test "greets the world" do
    assert Tony.hello() == :world
  end
end
