defmodule QCloud.VODTest do
  use ExUnit.Case

  alias QCloud.VOD

  @app :ku800
  @mp4_file_path Path.expand("./test/fixtures/trailer.mp4")

  describe "get_signature_v2" do
    test "ok" do
      VOD.get_signature_v2(@app, one_time_valid: true)
      |> QCloud.Logger.log_info()
    end
  end

  # describe "process media" do
  #   test "ok" do
  #     VOD.process_media(@app, "5285890789943757493",
  #       watermark: true,
  #       definitions: [20, 30]
  #     )
  #     |> QCloud.Logger.log_info()
  #   end
  # end

  describe "upload flow logics" do
    test "error" do
      assert VOD.apply_upload(@app) ==
               {:error, 200,
                %{
                  code: "MissingParameter",
                  message: "The request is missing a required parameter `MediaType`."
                }}
    end

    test "ok" do
      {:ok, data} = VOD.apply_upload(@app, media_type: "mp4", media_name: "/u/1024/a/512")

      temp_certificate = data[:temp_certificate]

      assert data[:temp_certificate][:ExpiredTime] > Timex.now() |> Timex.to_unix()
      assert data[:cover_storage_path] |> String.length() == 0
      assert data[:media_storage_path] |> String.length() > 0
      assert data[:request_id] |> String.length() > 0
      assert data[:vod_session_key] |> String.length() > 0
      assert data[:storage_bucket] |> String.length() > 0
      assert data[:storage_region] == "ap-guangzhou-2"

      # 简单上传
      upload_result =
        VOD.simple_upload(
          @app,
          File.read!(@mp4_file_path),
          QCloud.mime_type!(@mp4_file_path),
          storage_path: data[:media_storage_path],
          storage_region: data[:storage_region],
          storage_bucket: data[:storage_bucket],
          token: temp_certificate[:Token],
          secret_id: temp_certificate[:SecretId],
          secret_key: temp_certificate[:SecretKey]
        )
        |> QCloud.Logger.log_info()

      assert {:ok, 200, _} = upload_result

      # 确认上传
      assert {:ok,
              %{
                cover_url: cover_url,
                file_id: file_id,
                media_url: media_url,
                request_id: _request_id
              }} =
               VOD.commit_upload(@app,
                 vod_session_key: data[:vod_session_key]
               )

      assert cover_url |> String.length() == 0
      assert file_id |> String.length() > 0
      assert media_url |> String.length() > 0

      # 转码测试
      assert {:ok,
              %{
                request_id: request_id,
                task_id: task_id
              }} =
               VOD.process_media(@app, file_id,
                 watermark: true,
                 definitions: [20]
               )

      assert request_id |> String.length() > 0
      assert task_id |> String.length() > 0

      # 查看视频的信息
      assert {:ok, _} = VOD.describe_media_infos(@app, [file_id]) |> QCloud.Logger.log_info()

      # 修改视频信息
      assert {:ok, _} = VOD.medify_media_info(@app, file_id, name: "哈哈哈😀") |> QCloud.Logger.log_info()

      # 删除视频信息
      assert {:ok, _} = VOD.delete_media(@app, file_id) |> QCloud.Logger.log_info()
    end
  end
end
