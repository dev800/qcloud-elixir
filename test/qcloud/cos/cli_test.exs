defmodule QCloud.COSTest do
  use ExUnit.Case

  alias QCloud.COS

  @app :ku800
  @mp4_file_path Path.expand("./test/fixtures/trailer.mp4")

  describe "upload flow logics" do
    test "ok" do
      {:ok, data} =
        COS.put_object(
          @app,
          File.read!(@mp4_file_path),
          QCloud.mime_type!(@mp4_file_path),
          "/dev/video/trailer.mp4"
        )

      assert data[:status_code] == 200
    end
  end
end
