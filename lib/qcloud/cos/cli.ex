defmodule QCloud.COS do
  @moduledoc """
  api: https://cloud.tencent.com/document/product/436/7778
  """

  import SweetXml

  @configs Application.get_env(:qcloud, :apps)
  @long_timeout 2 * 60 * 1000
  @long_recv_timeout 2 * 60 * 1000

  def get_config(app) do
    @configs |> Keyword.get(app, %{}) |> Map.get(:cos, %{})
  end

  @doc """
  获取对象的头信息

  doc: https://cloud.tencent.com/document/product/436/7745
  """
  def head_object(app, path, opts \\ []) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    gmt_date = _generate_gmt_date()
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    "http://#{host}#{path}"
    |> HTTPoison.head([
      {"date", gmt_date},
      {"host", host},
      {"authorization",
       _auth_string(
         secret_id: opts[:secret_id] || config[:secret_id],
         secret_key: opts[:secret_key] || config[:secret_key],
         method: "head",
         host: host,
         path: path,
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
  def delete_object(app, path, opts \\ []) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    gmt_date = _generate_gmt_date()
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    "http://#{host}#{path}"
    |> HTTPoison.delete([
      {"date", gmt_date},
      {"host", host},
      {"authorization",
       _auth_string(
         secret_id: opts[:secret_id] || config[:secret_id],
         secret_key: opts[:secret_key] || config[:secret_key],
         method: "delete",
         host: host,
         path: path,
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
  def get_object(app, path, opts \\ []) do
    config = app |> get_config()
    host = config |> Map.get(:host)
    gmt_date = _generate_gmt_date()
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    "http://#{host}#{path}"
    |> HTTPoison.get([
      {"date", gmt_date},
      {"host", host},
      {"authorization",
       _auth_string(
         secret_id: opts[:secret_id] || config[:secret_id],
         secret_key: opts[:secret_key] || config[:secret_key],
         method: "get",
         host: host,
         path: path,
         config: config,
         gmt_date: gmt_date
       )}
    ])
    |> _parse_response()
  end

  @doc """
  提交对象数据

  doc: https://cloud.tencent.com/document/product/436/7749

  ## app

  ## file

  ## content_type

  ## path

  ## opts

  * `:host`
  * `:secret_id`
  * `:secret_key`
  """
  def put_object(app, file, content_type, path, opts \\ []) do
    config = app |> get_config()
    host = opts[:host] || config[:host]
    content_sha = :sha |> :crypto.hash(file) |> Base.encode16(case: :lower)
    storage_class = "standard"
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    "http://#{host}#{path}"
    |> HTTPoison.put(
      file,
      [
        {"content-type", content_type},
        {"host", host},
        {"x-cos-content-sha1", content_sha},
        {"x-cos-storage-class", storage_class},
        {"x-cos-security-token", opts[:token]},
        {"authorization",
         _auth_string(
           secret_id: opts[:secret_id] || config[:secret_id],
           secret_key: opts[:secret_key] || config[:secret_key],
           token: opts[:token],
           method: "put",
           host: host,
           path: path,
           content_type: content_type,
           content_sha: content_sha,
           storage_class: storage_class
         )}
      ],
      timeout: @long_timeout,
      recv_timeout: @long_recv_timeout
    )
    |> _parse_response()
  end

  # https://cloud.tencent.com/document/product/436/7778
  defp _auth_string(opts) do
    host = opts[:host]
    content_sha = opts[:content_sha]
    content_type = opts[:content_type]
    storage_class = opts[:storage_class]
    secret_id = opts[:secret_id]
    secret_key = opts[:secret_key]
    start_time = Timex.now() |> Timex.to_unix()
    end_time = start_time + 80006
    time = "#{start_time};#{end_time}"

    headers =
      [
        "content-type": content_type,
        host: host,
        "x-cos-content-sha1": content_sha,
        "x-cos-security-token": opts[:token],
        "x-cos-storage-class": storage_class
      ]
      |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 < k2 end)
      |> Enum.filter(fn {_k, v} -> String.length("#{v}") > 0 end)

    http_string =
      [
        opts[:method],
        opts[:path],
        "",
        headers |> URI.encode_query(),
        ""
      ]
      |> Enum.join("\n")

    http_string_sha = :sha |> :crypto.hash(http_string) |> Base.encode16(case: :lower)

    sign_key =
      :sha
      |> :crypto.hmac(secret_key, time)
      |> Base.encode16(case: :lower)

    string_to_sign = "sha1\n#{time}\n#{http_string_sha}\n"

    signature =
      :sha
      |> :crypto.hmac(sign_key, string_to_sign)
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
    response |> IO.inspect()

    error =
      response.body
      |> case do
        "" ->
          %{
            code: "Error",
            message: "Error"
          }

        body ->
          SweetXml.xpath(body, ~x"//Error",
            code: ~x"./Code/text()"so,
            message: ~x"./Message/text()"so,
            request_id: ~x"./RequestId/text()"so,
            resource: ~x"./Resource/text()"so,
            trace_id: ~x"./TraceId/text()"so
          )
      end

    {:error, status_code, %{body: response.body, headers: response.headers, error: error}}
  end

  defp _parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end

  defp _generate_gmt_date do
    Timex.now() |> Timex.format!("%a, %d %b %Y %H:%M:%S GMT", :strftime)
  end
end
