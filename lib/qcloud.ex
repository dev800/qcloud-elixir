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
end
