defmodule Tony.Environment do
  alias __MODULE__

  @functions [
    "+",
    "-",
    "*",
    "/",
    "defun",
    "and",
    "or",
    "not"
  ]

  defstruct curr_scope: nil,
            out_scope: nil,
            build_in: nil

  def new(), do: %Environment{build_in: @functions}

  def get(env, key) do
    value = get(env, :curr_scope, key)

    if is_nil(value) do
      get(env, :out_scope, key)
    else
      value
    end
  end

  def get(env, :curr_scope, key) do
    Map.get(env.curr_scope, key)
  end

  def get(env, :out_scope, key) do
    Map.get(env.out_scope, key)
  end
end
