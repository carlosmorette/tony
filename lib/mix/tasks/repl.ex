defmodule Mix.Tasks.Repl do
  use Mix.Task

  def run(_), do: read(nil)

  def read(env) do
    env =
      IO.gets("tony> ")
      |> eval(env)
      |> print()

    read(env)
  end

  def eval(input, env) do
    try do
      input
      |> Tony.Tokenizer.run()
      |> Tony.Parser.run()
      |> Tony.Eval.run(env)
      |> then(fn {env, result} -> {:ok, env, result} end)
    rescue
      err ->
        message =
          case err do
            %FunctionClauseError{module: module, function: function, arity: arity} ->
              """
              Error: Function #{module}.#{function}/#{arity} doesn't exists.
              """

            err ->
              """
              Error: #{err.message}
              """
          end

        {:error, env, message}
    end
  end

  def print({:error, env, message}) do
    IO.puts(message)

    env
  end

  def print({:ok, env, result}) do
    IO.puts(result)

    env
  end
end
