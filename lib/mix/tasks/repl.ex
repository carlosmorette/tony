defmodule Mix.Tasks.Repl do
  use Mix.Task

  def run(_), do: read(Tony.Environment.new())

  def read(env) do
    env =
      IO.gets("tony> ")
      |> eval(env)
      |> print()

    read(env)
  end

  def eval(input, env) do
    input
    |> Tony.run(env)
    |> then(fn
      {:ok, env, result} -> {:ok, env, result}
      {:error, err} -> {:error, env, err}
    end)
  end

  def print({:error, env, err}) do
    IO.puts("Error: #{inspect(err)}")

    env
  end

  def print({:ok, env, result}) do
    Tony.print(result)

    env
  end
end
