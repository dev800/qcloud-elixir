defmodule QCloudTest do
  use ExUnit.Case
  doctest QCloud

  @mp4_file_path Path.expand("./test/fixtures/trailer.mp4")

  test "greets the world" do
    assert QCloud.hello() == :world
  end

  test "mime_type" do
    assert QCloud.mime_type(@mp4_file_path) == {:ok, "video/mp4"}
  end
end
