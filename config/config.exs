use Mix.Config

config :qcloud, :apps,
  ku800: %{
    cos: %{
      app_id: "xxx",
      host: "xxx.ap-guangzhou.myqcloud.com",
      bucket: "xxx",
      secret_id: "xxx",
      secret_key: "xxx"
    },
    vod: %{
      host: "vod.api.qcloud.com",
      app_id: "xxx",
      region: "xxx",
      secret_id: "xxx",
      secret_key: "xxx",
      tags: %{
        default: %{id: "xxx"}
      },
      available_definitions: [20, 30],
      watermarks: %{
        default: %{id: "xxx"},
        i20: %{id: "xxx"},
        i30: %{id: "xxx"}
      }
    }
  }

if File.exists?("#{__DIR__}/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end

if File.exists?("#{__DIR__}/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
