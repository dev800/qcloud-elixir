defmodule QCloud.VOD do
  @moduledoc """
  url: https://cloud.tencent.com/product/vod
  doc: https://cloud.tencent.com/product/vod/developer
  api: https://cloud.tencent.com/document/product/266/10688 (2017年版本)
  api: https://cloud.tencent.com/document/product/266/31753 （2018年版本）
  """

  alias QCloud.COS

  @configs Application.get_env(:qcloud, :apps)

  def get_config(app) do
    @configs |> Keyword.get(app, %{}) |> Map.get(:vod, %{})
  end

  @doc """
  获取视频信息

  url: https://cloud.tencent.com/document/api/266/31764

  ## file_id

  ## opts

  * `:parts` eg. [["Type", "TranscodeFiles"], ["Definition", "230"]]
  """
  def delete_media(app, file_id, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "DeleteMedia")
      |> Keyword.put(:path, "/")

    params = [
      Action: "DeleteMedia",
      Version: "2018-07-17",
      SubAppId: opts[:sub_app_id],
      FileId: file_id
    ]

    params =
      opts
      |> Keyword.get(:parts, [])
      |> Enum.with_index()
      |> Enum.reduce(params, fn {part, index}, params ->
        params |> Keyword.put(:"DeleteParts.#{index}.#{part |> Enum.at(0)}", part[1])
      end)

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           RequestId: request_id
         }
       }} ->
        {:ok, %{request_id: request_id}}

      error ->
        error
    end
  end

  @doc """
  修改视频信息

  url: https://cloud.tencent.com/document/api/266/31762

  ## file_id

  ## opts

  * `:name`
  * `:description`
  * `:class_tag`
  * `:clear_key_frame_descs`
  * `:add_key_frame_descs`    eg. [[1.0, "春天来了", ["10.2", "夏天来了"]]
  * `:delete_key_frame_descs`
  * `:clear_tags`
  """
  def modify_media_info(app, file_id, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "ModifyMediaInfo")
      |> Keyword.put(:path, "/")

    params =
      [
        Action: "ModifyMediaInfo",
        Version: "2018-07-17",
        FileId: file_id,
        SubAppId: opts[:sub_app_id]
      ]
      |> QCloud.if_call(opts[:name], fn params ->
        params |> Keyword.put(:Name, opts[:name])
      end)
      |> QCloud.if_call(opts[:description], fn params ->
        params |> Keyword.put(:Description, opts[:description])
      end)
      |> QCloud.if_call(opts[:class_tag], fn params ->
        class_id =
          conf
          |> get_in([:tags, opts[:class_tag] || :default, :id])
          |> Kernel.||(0)

        params |> Keyword.put(:ClassId, class_id)
      end)
      |> QCloud.if_call(opts[:cover_data], fn params ->
        params |> Keyword.put(:CoverData, opts[:cover_data])
      end)
      |> QCloud.if_call(opts[:clear_key_frame_descs], fn params ->
        params |> Keyword.put(:ClearKeyFrameDescs, 1)
      end)
      |> QCloud.if_call(opts[:clear_tags], fn params ->
        params |> Keyword.put(:ClearTags, 1)
      end)

    params =
      opts
      |> Keyword.get(:add_key_frame_descs, [])
      |> Enum.with_index()
      |> Enum.reduce(params, fn {desc, index}, params ->
        params
        |> Keyword.put(:"AddKeyFrameDescs.#{index}.TimeOffset", desc |> Enum.at(0))
        |> Keyword.put(:"AddKeyFrameDescs.#{index}.Content", desc |> Enum.at(0))
      end)

    params =
      opts
      |> Keyword.get(:delete_key_frame_descs, [])
      |> Enum.with_index()
      |> Enum.reduce(params, fn {offset, index}, params ->
        params |> Keyword.put(:"DeleteKeyFrameDescs.#{index}", offset)
      end)

    params =
      opts
      |> Keyword.get(:add_tags, [])
      |> Enum.with_index()
      |> Enum.reduce(params, fn {tag, index}, params ->
        params |> Keyword.put(:"AddTags.#{index}", tag)
      end)

    params =
      opts
      |> Keyword.get(:delete_tags, [])
      |> Enum.with_index()
      |> Enum.reduce(params, fn {tag, index}, params ->
        params |> Keyword.put(:"DeleteTags.#{index}", tag)
      end)

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           RequestId: request_id,
           MediaInfoSet: mediaInfoSet
         }
       }} ->
        {:ok, %{request_id: request_id, mediaInfoSet: mediaInfoSet}}

      error ->
        error
    end
  end

  @doc """
  获取视频信息

  url: https://cloud.tencent.com/document/product/266/8586

  ## file_ids

  ## opts

  * `:filters`
  """
  def describe_media_infos(app, file_ids, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "DescribeMediaInfos")
      |> Keyword.put(:path, "/")

    params = [
      Action: "DescribeMediaInfos",
      Version: "2018-07-17",
      SubAppId: opts[:sub_app_id]
    ]

    params =
      file_ids
      |> Enum.with_index()
      |> Enum.reduce(params, fn {file_id, index}, params ->
        params |> Keyword.put(:"FileIds.#{index}", file_id)
      end)

    params =
      opts
      |> Keyword.get(:filters, [])
      |> Enum.with_index()
      |> Enum.reduce(params, fn {filter, index}, params ->
        params |> Keyword.put(:"Filters.#{index}", filter)
      end)

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           RequestId: request_id,
           MediaInfoSet: mediaInfoSet
         }
       }} ->
        {:ok, %{request_id: request_id, mediaInfoSet: mediaInfoSet}}

      error ->
        error
    end
  end

  @doc """
  获取任务信息

  url: https://cloud.tencent.com/document/api/266/33431

  ## task_id

  ## opts

  * `:sub_app_id`
  """
  def describe_task_detail(app, task_id, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "DescribeTaskDetail")
      |> Keyword.put(:path, "/")

    params = [
      Action: "DescribeTaskDetail",
      Version: "2018-07-17",
      TaskId: task_id,
      SubAppId: opts[:sub_app_id]
    ]

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           TaskType: taskType,
           Status: status,
           CreateTime: createdAt,
           BeginProcessTime: beginProcessAt,
           FinishTime: finishAt,
           ProcedureTask: procedureTask,
           EditMediaTask: editMediaTask,
           WechatPublishTask: wechatPublishTask,
           TranscodeTask: transcodeTask,
           SnapshotByTimeOffsetTask: snapshotByTimeOffsetTask,
           ConcatTask: concatTask,
           ClipTask: clipTask,
           CreateImageSpriteTask: createImageSpriteTask,
           RequestId: request_id
         }
       }} ->
        {:ok,
         %{
           request_id: request_id,
           status: status,
           taskType: taskType,
           createdAt: createdAt,
           beginProcessAt: beginProcessAt,
           finishAt: finishAt,
           procedureTask: procedureTask,
           editMediaTask: editMediaTask,
           wechatPublishTask: wechatPublishTask,
           transcodeTask: transcodeTask,
           snapshotByTimeOffsetTask: snapshotByTimeOffsetTask,
           concatTask: concatTask,
           clipTask: clipTask,
           createImageSpriteTask: createImageSpriteTask
         }}

      error ->
        error
    end
  end

  @doc """
  使用任务流模板进行视频处理

  url: https://cloud.tencent.com/document/product/266/34782

  ## file_id

  ## procedure
  """
  def process_media_by_procedure(app, file_id, procedure \\ :default, opts \\ []) do
    conf = get_config(app)

    procedure_name =
      conf
      |> get_in([:procedures, procedure])
      |> Kernel.||(get_in(conf, [:procedures, :deafult]))

    params = [
      Action: "ProcessMediaByProcedure",
      FileId: file_id,
      Version: "2018-07-17",
      ProcedureName: procedure_name
    ]

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "ProcessMediaByProcedure")
      |> Keyword.put(:path, "/")

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           RequestId: request_id,
           TaskId: task_id
         }
       }} ->
        {:ok,
         %{
           request_id: request_id,
           task_id: task_id
         }}

      error ->
        error
    end
  end

  @doc """
  视频处理：加水印等

  url: https://cloud.tencent.com/document/product/266/33427

  ## opts

  * `:file_id` 文件ID
  * `:watermark` true/false
  * `:definitions` 20/30 eg. [20, 30]
  * `:sample_snapshots` [10]
  """
  def process_media(app, file_id, opts \\ []) do
    conf = get_config(app)
    available_definitions = conf[:available_definitions] || []

    definitions =
      opts
      |> Keyword.get(:definitions, [20])
      |> Enum.filter(fn definition ->
        Enum.member?(available_definitions, definition)
      end)

    params = [
      Action: "ProcessMedia",
      FileId: file_id,
      Version: "2018-07-17"
    ]

    params =
      definitions
      |> Enum.with_index()
      |> Enum.reduce(params, fn {definition, index}, params ->
        params =
          params ++ [{:"MediaProcessTask.TranscodeTaskSet.#{index}.Definition", definition}]

        if opts |> Keyword.get(:watermark, true) do
          watermark_id =
            conf[:watermarks]
            |> get_in([:"i#{definition}", :id])
            |> Kernel.||(conf |> get_in([:watermarks, :default]))

          params ++
            [
              {:"MediaProcessTask.TranscodeTaskSet.#{index}.WatermarkSet.0.Definition",
               watermark_id}
            ]
        else
          params
        end
      end)
      |> Keyword.new()

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "ProcessMedia")
      |> Keyword.put(:path, "/")

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           RequestId: request_id,
           TaskId: task_id
         }
       }} ->
        {:ok,
         %{
           request_id: request_id,
           task_id: task_id
         }}

      error ->
        error
    end
  end

  @doc """
  获取客户端上传需要的票据

  url: https://cloud.tencent.com/document/product/266/9221

  ## opts

  * `:class_tag`
  * `:one_time_valid`
  """
  def get_signature_v2(app, opts \\ []) do
    conf = get_config(app)

    timestamp = Timex.now() |> Timex.to_unix()
    expireTime = Timex.now() |> Timex.shift(months: 6) |> Timex.to_unix()

    class_id =
      conf
      |> get_in([:tags, opts[:class_tag] || :default, :id])
      |> Kernel.||(0)

    params =
      [
        secretId: conf[:secret_id],
        currentTimeStamp: timestamp,
        expireTime: expireTime,
        random: :random.uniform(1_000_000),
        classId: class_id,
        procedure: opts[:procedure],
        taskPriority: opts[:task_riority],
        taskNotifyMode: opts[:task_notify_mode] || "Finish",
        sourceContext: opts[:source_context],
        oneTimeValid: if(opts[:one_time_valid], do: 1, else: 0)
      ]
      |> _params_normalize()

    query_string = params |> URI.encode_query()

    :crypto.hmac(:sha, conf[:secret_key], query_string)
    |> Kernel.<>(query_string)
    |> Base.encode64()
  end

  @doc """
  发起上传

  url: https://cloud.tencent.com/document/product/266/31767

  ## opts

  * `:media_type`
    - 视频：mp4，ts，flv，wmv，asf，rm，rmvb，mpg，mpeg，3gp，mov，webm，mkv，avi。
    - 音频：mp3，m4a，flac，ogg，wav

  * `:media_name`

  * `:cover_type`
    - 封面类型 jpg，jpeg，png，gif，bmp，tiff，ai，cdr，eps。

  * `:procedure`
  * `:expire_time`
  * `:storage_region`
  * `:class_tag`
  * `:source_context`
  * `:sub_app_id`
  """
  def apply_upload(app, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "ApplyUpload")
      |> Keyword.put(:path, "/")

    class_id =
      conf
      |> get_in([:tags, opts[:class_tag] || :default, :id])
      |> Kernel.||(0)

    params = [
      Action: "ApplyUpload",
      Version: "2018-07-17",
      Region: conf[:region],
      MediaType: opts[:media_type],
      MediaName: opts[:media_name],
      CoverType: opts[:cover_type],
      Procedure: opts[:procedure],
      ExpireTime: opts[:expire_ime],
      StorageRegion: opts[:storage_region],
      ClassId: class_id,
      SourceContext: opts[:source_context],
      SubAppId: opts[:sub_app_id]
    ]

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           CoverStoragePath: cover_storage_path,
           MediaStoragePath: media_storage_path,
           RequestId: request_id,
           StorageBucket: storage_bucket,
           StorageRegion: storage_region,
           TempCertificate: temp_certificate,
           # %{
           #   ExpiredTime: 1_559_796_587,
           #   SecretId: "AKIDIGyo57k4KZx6ps9UmQiFLxO1X4Ht94LX",
           #   SecretKey: "gKcR4zjHpdP0eUPQNUtJLDvlEbi2uYNW",
           #   Token: "382c1d9b532e57e6a9cba7503c6c4989adc12ef430001"
           # },
           VodSessionKey: vod_session_key
         }
       }} ->
        {:ok,
         %{
           cover_storage_path: cover_storage_path,
           media_storage_path: media_storage_path,
           request_id: request_id,
           storage_bucket: storage_bucket,
           storage_region: storage_region,
           temp_certificate: temp_certificate,
           vod_session_key: vod_session_key
         }}

      error ->
        error
    end
  end

  @doc """
  确认上传

  url: https://cloud.tencent.com/document/product/266/31766

  ## opts

  * `:vod_session_key`
  * `:sub_app_id`
  """
  def commit_upload(app, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.tencentcloudapi.com")
      |> Keyword.put(:action, "CommitUpload")
      |> Keyword.put(:path, "/")

    params = [
      Action: "CommitUpload",
      Version: "2018-07-17",
      Region: conf[:region],
      VodSessionKey: opts[:vod_session_key],
      SubAppId: opts[:sub_app_id]
    ]

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> _parse_response()
    |> case do
      {:ok,
       %{
         Response: %{
           FileId: file_id,
           MediaUrl: media_url,
           CoverUrl: cover_url,
           RequestId: request_id
         }
       }} ->
        {:ok,
         %{
           file_id: file_id,
           media_url: media_url,
           cover_url: cover_url,
           request_id: request_id
         }}

      error ->
        error
    end
  end

  @doc """
  简单上传

  url: https://cloud.tencent.com/document/product/266/9758

  ## app

  ## file

  ## content_type

  ## opts

  * `:storage_path`
  * `:storage_region`
  * `:storage_bucket`
  * `:secret_id`
  * `:secret_key`
  * `:token`
  """
  def simple_upload(app, file, content_type, opts \\ []) do
    path = opts[:storage_path]
    host = "#{opts[:storage_bucket]}.cos.#{opts[:storage_region]}.myqcloud.com"

    opts =
      opts
      |> Keyword.put(:host, host)
      |> Keyword.put(:token, opts[:token])
      |> Keyword.put(:secret_id, opts[:secret_id])
      |> Keyword.put(:secret_key, opts[:secret_key])

    COS.put_object(app, file, content_type, path, opts)
  end

  defp _build_url(conf, params, opts) do
    timestamp = Timex.now() |> Timex.to_unix()
    secret_id = opts[:secret_id] || conf[:secret_id]
    secret_key = opts[:secret_key] || conf[:secret_key]

    params =
      params
      |> Keyword.merge(
        Action: opts[:action],
        Nonce: :random.uniform(10_000_000),
        SecretId: secret_id,
        Timestamp: timestamp
      )
      |> _params_normalize()

    src =
      [
        "#{opts[:method]}" |> String.upcase(),
        opts[:host],
        opts[:path] || "/",
        "?",
        params |> _join_pairs()
      ]
      |> Enum.join()

    signature = :crypto.hmac(:sha, secret_key, src) |> Base.encode64()

    params =
      params
      |> Keyword.put(:Signature, signature)
      |> _params_normalize()

    [
      "https://",
      opts[:host],
      opts[:path],
      "?",
      URI.encode_query(params)
    ]
    |> Enum.join()
    |> QCloud.Logger.log_info()
  end

  defp _params_normalize(params) do
    params
    |> Enum.filter(fn {_k, v} -> String.length("#{v}") > 0 end)
    |> Enum.sort(fn {k, _v}, {k2, _v2} -> k < k2 end)
  end

  defp _join_pairs(params) do
    params
    |> Enum.map(fn {k, v} ->
      "#{k}=#{v}"
    end)
    |> Enum.join("&")
  end

  defp _parse_response(response) do
    response
    |> case do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        body
        |> Jason.decode(keys: :atoms)
        |> case do
          {:ok,
           %{
             Response: %{
               Error: %{
                 Code: code,
                 Message: message
               }
             }
           }} ->
            {:error, 200, %{code: code, message: message}}

          {:ok, data} ->
            {:ok, data}
        end

      {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: status_code}} ->
        {:error, status_code, %{body: body, headers: headers}}
    end
  end
end
