defmodule QCloud do
  @moduledoc """
  Documentation for QCloud.
  """

  @doc """
  Hello world.

  ## Examples

      iex> QCloud.hello
      :world

  """
  def hello do
    :world
  end

  def if_call(q, condition \\ true, true_fn)

  def if_call(q, condition, true_fn) do
    if condition, do: true_fn.(q), else: q
  end

  def mime_type(file_path) do
    case System.cmd("file", ["--mime-type", "-b", file_path], stderr_to_stdout: true) do
      {rows_text, 0} ->
        rows_text = rows_text |> String.trim()

        cond do
          String.starts_with?(rows_text, "cannot open") ->
            {:error, :cannot_open}

          String.contains?(rows_text, " ") ->
            {:error, :invalid}

          true ->
            {:ok,
             rows_text
             |> String.split(";")
             |> Enum.map(fn s -> String.trim(s) end)
             |> List.first()}
        end

      {error_message, 1} ->
        {:error, :"#{error_message}"}
    end
  end

  def mime_type!(file_path) do
    file_path
    |> mime_type()
    |> case do
      {:ok, type} -> type
      {:error, error_reason} -> raise(ArgumentError, "#{error_reason}")
    end
  end
end
