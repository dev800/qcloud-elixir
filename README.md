# QCloud

## Installation

> 注意：文档不详细，因为项目比较忙，暂时先写这么多

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `qcloud` to your list of dependencies in `mix.exs`:

```elixir
## step 1 -> mix.exs
def deps do
  [
    {:qcloud, "~> 0.1"}
  ]
end

## step 2

mix deps.get

## step 3 -> config/xxx.exs
config :qcloud, :apps,
  hello_world: %{   # your app name
    cos: %{
      app_id: "xxx",    # your config
      host: "xxx",      # your config
      bucket: "xxx",    # your config
      secret_id: "xxx", # your config
      secret_key: "xxx" # your config
    }
  }

## step 4 for use

### eg.
QCloud.COS.get_object(:hello_world, "files/helloworld.jpg")
QCloud.COS.put_object(:hello_world, file, "image/jpeg", "files/helloworld.jpg")
QCloud.COS.delete_object(:hello_world, "files/helloworld.jpg")
QCloud.COS.head_object(:hello_world, "files/helloworld.jpg")
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/qcloud](https://hexdocs.pm/qcloud).

