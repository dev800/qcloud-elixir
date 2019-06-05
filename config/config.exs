use Mix.Config

config :qcloud, :apps,
  app_name: %{
    cos: %{
      app_id: "xxx",
      host: "xxx",
      bucket: "xxx",
      secret_id: "xxx",
      secret_key: "xxx"
    }
  }

if File.exists?("#{__DIR__}/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end

if File.exists?("#{__DIR__}/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
