defmodule QCloud.VOD do
  @moduledoc """
  url: https://cloud.tencent.com/product/vod
  doc: https://cloud.tencent.com/product/vod/developer
  api: https://cloud.tencent.com/document/product/266/10688
  """

  @configs Application.get_env(:qcloud, :apps)

  def get_config(app) do
    @configs |> Keyword.get(app, %{}) |> Map.get(:vod, %{})
  end

  @doc """
  url: https://cloud.tencent.com/document/product/266/33427

  ## opts

  * `:file_id` 文件ID
  * `:watermark` true/false
  * `:definitions` 20/30 eg. [20, 30]
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
  end

  @doc """
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

    params = [
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

    params =
      params
      |> Enum.filter(fn {_k, v} -> String.length("#{v}") > 0 end)
      |> Enum.sort(fn {k, _v}, {k2, _v2} -> k < k2 end)

    query_string = params |> URI.encode_query()

    :crypto.hmac(:sha, conf[:secret_key], query_string)
    |> Kernel.<>(query_string)
    |> Base.encode64()
  end

  @doc """
  发起上传

  url: https://cloud.tencent.com/document/product/266/9756

  ## opts

  * `video_type` 必填
  * `video_name`
  * `cover_type`
  * `cover_name`
  * `source_context`
  * `procedure`
  * `video_storage_path`
  * `class_tag`
  """
  def apply_upload(app, opts \\ []) do
    conf = get_config(app)

    opts =
      opts
      |> Keyword.put(:method, "GET")
      |> Keyword.put(:host, "vod.api.qcloud.com")
      |> Keyword.put(:action, "ApplyUpload")
      |> Keyword.put(:path, "/v2/index.php")

    class_id =
      conf
      |> get_in([:tags, opts[:class_tag] || :default, :id])
      |> Kernel.||(0)

    params = [
      Region: conf[:region],
      videoType: opts[:video_type],
      videoName: opts[:video_name],
      coverType: opts[:cover_type],
      coverName: opts[:cover_name],
      sourceContext: opts[:source_context],
      procedure: opts[:procedure],
      videoStoragePath: opts[:video_storage_path],
      classId: class_id
    ]

    conf
    |> _build_url(params, opts)
    |> HTTPoison.get()
    |> case do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        body
        |> Jason.decode(keys: :atoms)
        |> case do
          {:ok, %{code: 0} = data} ->
            # eg.
            #  %{
            #    code: 0,
            #    codeDesc: "Success",
            #    message: "",
            #    storageAppId: 10_022_853,
            #    storageBucket: "8aaa9f5evodgzp1251033691",
            #    storageRegion: "gzp",
            #    storageRegionV5: "ap-guangzhou-2",
            #    video: %{
            #      storagePath:
            #        "/8aaa9f5evodgzp1251033691/3eb051435285890789923358946/7vMDjanAGZMA.mp4",
            #      storageSignature:
            #        "JeYneTwaHcHkdajSATTKzXNGa1RhPTEwMDIyODUzJmI9OGFhYTlmNWV2b2RnenAxMjUxMDMzNjkxJms9QUtJRElXZTdBdEkxMFBRa204UkVEbDRVTzdJNm15bjZOREY3JmU9MTU1OTg5NjUzMiZ0PTE1NTk3MjM3MzImcj0xOTk5Nzg3NzYzJmY9LzEwMDIyODUzLzhhYWE5ZjVldm9kZ3pwMTI1MTAzMzY5MS84YWFhOWY1ZXZvZGd6cDEyNTEwMzM2OTEvM2ViMDUxNDM1Mjg1ODkwNzg5OTIzMzU4OTQ2Lzd2TURqYW5BR1pNQS5tcDQ="
            #    },
            #    vodSessionKey:
            #      "3FEmq9DWHlB/Cekv0oUhRk1a35GeKd8umpeWV5N04EAOH1swAIGPs5h01B0pVHAm3VKVkSo5zEKZ+lH3eLQ3xWDo2ChWHOwjJPcT5ed46J3BY4/0JAqcaHeOT4pqGG669aUPCpRGeaCgeAt8fZO8zE54ZPFyR+fHArmvGxhET22ULjE5Ou63A5GDQJMHrKuNSJyByvzLQP/9JSYJlvLhIhpS57iMtIWjEbUdk1gF7CcQ7joxSs13HhWMmSbSukOZk58hTOhtTaJXRa9+24eAkUaq7jNIleMxot2NdcDnee/mMLb5AB3WsU38iKDgAGQAp4s0JKkyl4pJ0v7X35HOgajrBEStSIGwpgi6jtv6LdMYqV2nLzc/PyvZSOUAwaZrcBFHRVGmqLmw56+Kfpz8wNTgWXegvRAT+IZl14tjOuOnfoQyVw6rs9QhBQJIHHa0dpKr5m4qBM7kaMqjwU7Wpw=="
            #  }

            {:ok,
             %{
               code: data[:code],
               logic: data[:codeDesc],
               message: data[:message],
               storageAppId: data[:storageAppId],
               storageBucket: data[:storageBucket],
               storageRegion: data[:storageRegion],
               storageRegionV5: data[:storageRegionV5],
               video: data[:video],
               cover: data[:cover],
               vodSessionKey: data[:vodSessionKey]
             }}

          {:ok, %{code: code, message: message, codeDesc: codeDesc}} ->
            {:error, 200, %{code: code, message: message, logic: codeDesc}}
        end

      {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: status_code}} ->
        {:error, status_code, %{body: body, headers: headers}}
    end
  end

  @doc """
  简单上传

  url: https://cloud.tencent.com/document/product/266/9758

  ## opts

  * `:appid`
  * `:bucket_name`
  * `:store_path`
  * `:region`
  * `:authorization`

  * `:file_path`
  * `:biz`
  """
  def simple_upload(app, opts \\ []) do
    _conf = get_config(app)

    biz_attr = opts[:biz] |> Jason.encode!()
    file_path = opts[:file_path]
    file = File.read!(file_path)
    file_sha1 = :crypto.hash(:sha, file) |> Base.encode16(case: :lower)
    content_type = QCloud.mime_type!(file_path)
    authorization = opts[:authorization]

    [
      "https://",
      "#{opts[:region]}.file.myqcloud.com",
      "/files/v2/#{opts[:appid]}/#{opts[:bucket_name]}#{opts[:store_path]}"
    ]
    |> Enum.join()
    |> HTTPoison.post(
      {:multipart,
       [
         {"sha", file_sha1},
         {"biz_attr", biz_attr},
         {"op", "upload"},
         {:file, file_path,
          {"form-data",
           [
             {"name", "filecontent"},
             {"filename", file_path}
           ]},
          [
            {"Content-Type", content_type}
          ]}
       ]},
      [{"Content-Type", "multipart/form-data"}, {"Authorization", authorization}]
    )
  end

  defp _build_url(conf, params, opts) do
    common_params = _common_params(conf, params, opts)

    [
      "https://",
      opts[:host],
      opts[:path],
      "?",
      common_params[:query_string],
      "&",
      URI.encode_query(%{Signature: common_params[:sign]})
    ]
    |> Enum.join()
  end

  ## opts
  #
  # * `:method`
  # * `:host`
  # * `:path`
  # * `:action`
  #
  defp _common_params(conf, params, opts) do
    timestamp = Timex.now() |> Timex.to_unix()

    query =
      params
      |> Keyword.merge(
        Action: opts[:action],
        Nonce: :random.uniform(1_000_000),
        SecretId: conf[:secret_id],
        Timestamp: timestamp
      )
      |> Enum.filter(fn {_k, v} -> String.length("#{v}") > 0 end)
      |> Enum.sort(fn {k, _v}, {k2, _v2} -> k < k2 end)

    query_string = query |> URI.encode_query()

    src =
      [
        "#{opts[:method]}" |> String.upcase(),
        opts[:host],
        opts[:path] || "/",
        "?",
        query_string
      ]
      |> Enum.join()

    sign = :crypto.hmac(:sha, conf[:secret_key], src) |> Base.encode64()

    %{
      query_string: query_string,
      query: query,
      src: src,
      sign: sign
    }
  end
end
