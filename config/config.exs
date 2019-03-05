use Mix.Config

if File.exists?("#{__DIR__}/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end

if File.exists?("#{__DIR__}/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
