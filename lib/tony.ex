defmodule Tony do
  alias Tony.{
    Eval,
    Parser,
    Tokenizer,
    Environment
  }

  @spec run(String.t(), %Environment{}) :: {:ok, %Environment{}, any()} | {:error, any()}
  def run(string, env \\ Environment.new()) do
    try do
      string
      |> Tokenizer.run()
      |> Parser.run()
      |> Eval.run(env)
      |> then(fn {env, result} -> {:ok, env, result} end)
    rescue
      err ->
        message =
          case err do
            %RuntimeError{message: message} ->
              message

            another_error ->
              another_error
          end

        print(message)
        {:error, message}
    end
  end

  @spec print(any()) :: :ok
  def print(value) do
    if is_struct(value) do
      IO.puts(value.__struct__)
    else
      IO.puts(value)
    end
  end
end
