defmodule QCloud.Logger do
  require Logger

  @default_options [pretty: true, charlists: false]

  defp _log_inspect(info, options) do
    options = @default_options |> Keyword.merge(options)
    inspect(info, options)
  end

  def log_inspect(info, options \\ []) do
    info |> _log_inspect(options)
    info
  end

  def log_debug(info, options \\ []) do
    info |> _log_inspect(options) |> Logger.debug(options)
    info
  end

  def log_info(info, options \\ []) do
    info |> _log_inspect(options) |> Logger.info(options)
    info
  end

  def log_warn(info, options \\ []) do
    info |> _log_inspect(options) |> Logger.warn(options)
    info
  end

  def log_error(info, options \\ []) do
    info |> _log_inspect(options) |> Logger.error(options)
    info
  end
end
