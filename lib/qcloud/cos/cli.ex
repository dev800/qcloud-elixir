defmodule QCloud.COS do
  @configs Application.get_env(:qcloud, :apps)

  def get_config(app) do
    @configs |> Keyword.get(app, %{}) |> Map.get(:cos, %{})
  end

  @doc """
  获取对象的头信息
  """
  def head_object(app, path) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    gmt_date = Timex.now() |> Timex.format!("%a, %d %b %Y %H:%M:%S GMT", :strftime)

    "http://#{host}/#{path}"
    |> HTTPoison.head([
      {"date", gmt_date},
      {"host", host},
      {"authorization",
       _auth_string(
         method: "head",
         host: host,
         uri: "/#{path}",
         config: config,
         gmt_date: gmt_date
       )}
    ])
  end

  @doc """
  删除对象
  """
  def delete_object(app, path) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    gmt_date = Timex.now() |> Timex.format!("%a, %d %b %Y %H:%M:%S GMT", :strftime)

    "http://#{host}/#{path}"
    |> HTTPoison.delete([
      {"date", gmt_date},
      {"host", host},
      {"authorization",
       _auth_string(
         method: "delete",
         host: host,
         uri: "/#{path}",
         config: config,
         gmt_date: gmt_date
       )}
    ])
  end

  @doc """
  获取对象数据
  """
  def get_object(app, path) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    gmt_date = Timex.now() |> Timex.format!("%a, %d %b %Y %H:%M:%S GMT", :strftime)

    "http://#{host}/#{path}"
    |> HTTPoison.get([
      {"date", gmt_date},
      {"host", host},
      {"authorization",
       _auth_string(
         method: "get",
         host: host,
         uri: "/#{path}",
         config: config,
         gmt_date: gmt_date
       )}
    ])
  end

  @doc """
  提交对象数据
  """
  def put_object(app, file, content_type, path) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    content_sha = :sha |> :crypto.hash(file) |> Base.encode16(case: :lower)
    storage_class = "standard"

    "http://#{host}/#{path}"
    |> HTTPoison.put(file, [
      {"content-type", content_type},
      {"x-cos-storage-class", storage_class},
      {"x-cos-content-sha1", content_sha},
      {"host", host},
      {"authorization",
       _auth_string(
         method: "put",
         host: host,
         uri: "/#{path}",
         config: config,
         content_type: content_type,
         content_sha: content_sha,
         storage_class: storage_class
       )}
    ])
  end

  defp _auth_string(opts) do
    # https://cloud.tencent.com/document/product/436/7778
    host = opts[:host]
    content_sha = opts[:content_sha]
    content_type = opts[:content_type]
    storage_class = opts[:storage_class]
    config = opts[:config] || %{}
    secret_id = config[:secret_id]
    secret_key = config[:secret_key]
    start_time = Timex.now() |> Timex.to_unix()
    end_time = start_time + 80006
    time = "#{start_time};#{end_time}"

    headers =
      [
        "content-type": content_type,
        host: host,
        "x-cos-content-sha1": content_sha,
        "x-cos-storage-class": storage_class
      ]
      |> Enum.filter(fn {_k, v} -> not is_nil(v) end)

    http_string =
      [
        opts[:method],
        opts[:uri],
        "",
        headers |> URI.encode_query(),
        ""
      ]
      |> Enum.join("\n")

    http_string_sha = :sha |> :crypto.hash(http_string) |> Base.encode16(case: :lower)

    secret_key_sign =
      :sha
      |> :crypto.hmac(secret_key, time)
      |> Base.encode16(case: :lower)

    string_to_sign = "sha1\n#{time}\n#{http_string_sha}\n"

    signature =
      :sha
      |> :crypto.hmac(secret_key_sign, string_to_sign)
      |> Base.encode16(case: :lower)

    [
      "q-sign-algorithm=sha1",
      "q-ak=#{secret_id}",
      "q-sign-time=#{time}",
      "q-key-time=#{time}",
      "q-header-list=#{headers |> Keyword.keys() |> Enum.join(";")}",
      "q-url-param-list=",
      "q-signature=#{signature}"
    ]
    |> Enum.join("&")
  end
end
