defmodule QCloud.COS do
  @moduledoc """
  doc: https://cloud.tencent.com/document/product/436/7778
  """

  import SweetXml

  @configs Application.get_env(:qcloud, :apps)

  def get_config(app) do
    @configs |> Keyword.get(app, %{}) |> Map.get(:cos, %{})
  end

  @doc """
  获取对象的头信息

  doc: https://cloud.tencent.com/document/product/436/7745
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
    |> _parse_response()
  end

  @doc """
  删除对象

  doc: https://cloud.tencent.com/document/product/436/8289
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
    |> _parse_response()
  end

  @doc """
  获取对象数据

  doc: https://cloud.tencent.com/document/product/436/7753
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
    |> _parse_response()
  end

  @doc """
  提交对象数据

  doc: https://cloud.tencent.com/document/product/436/7749
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
    |> _parse_response()
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
        "2",
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

  defp _parse_response({:ok, %HTTPoison.Response{status_code: status_code} = response})
       when status_code in 200..399 do
    {:ok, response.status_code,
     %{
       body: response.body,
       headers: response.headers,
       status_code: response.status_code,
       request: response.request,
       request_url: response.request_url
     }}
  end

  defp _parse_response({:ok, %HTTPoison.Response{status_code: status_code} = response}) do
    error =
      response.body
      |> SweetXml.xpath(~x"//Error",
        code: ~x"./Code/text()"so,
        message: ~x"./Message/text()"so,
        request_id: ~x"./RequestId/text()"so,
        resource: ~x"./Resource/text()"so,
        trace_id: ~x"./TraceId/text()"so
      )

    {:error, status_code, %{body: response.body, headers: response.headers, error: error}}
  end

  defp _parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end
end
