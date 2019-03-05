defmodule QCloudTest do
  use ExUnit.Case
  doctest QCloud

  test "greets the world" do
    assert QCloud.hello() == :world
  end
end
