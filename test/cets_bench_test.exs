defmodule CetsBenchTest do
  use ExUnit.Case
  doctest CetsBench

  test "greets the world" do
    assert CetsBench.hello() == :world
  end
end
