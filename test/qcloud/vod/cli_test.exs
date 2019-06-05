defmodule QCloud.VODTest do
  use ExUnit.Case

  alias QCloud.VOD

  # @mp4_file_path Path.expand("./test/fixtures/trailer.mp4")

  describe "get_signature_v2" do
    test "ok" do
      VOD.get_signature_v2(:ku800, one_time_valid: true)
      |> QCloud.Logger.log_info()
    end
  end

  describe "process media" do
    test "ok" do
      VOD.process_media(:ku800, "5285890789943757493",
        watermark: true,
        definitions: [20, 30]
      )
      |> QCloud.Logger.log_info()
    end
  end

  describe "upload flow logics" do
    test "error" do
      assert VOD.apply_upload(:ku800) ==
               {:error, 200,
                %{
                  code: 4000,
                  logic: "InvalidParameter",
                  message: "请求失败，参数[videoType]不能为空。"
                }}
    end

    test "ok" do
      # {:ok, data} = VOD.apply_upload(:ku800, video_type: "mp4")

      # assert data[:code] == 0
      # assert data[:logic] == "Success"
      # assert data[:storageRegion] == "gzp"
      # assert data[:storageRegionV5] == "ap-guangzhou-2"

      # video_data = data[:video]

      # upload_result =
      #   VOD.simple_upload(:ku800,
      #     appid: data[:storageAppId],
      #     bucket_name: data[:storageBucket],
      #     store_path: video_data[:storagePath],
      #     authorization: video_data[:storageSignature],
      #     region: data[:storageRegion],
      #     file_path: @mp4_file_path,
      #     biz: %{userId: 1024}
      #   )

      # assert upload_result == %{}
    end
  end
end
