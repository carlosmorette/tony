defmodule Tony do
  alias Tony.{Eval, Parser, Tokenizer}

  def run(input_path) do
    input_path
    |> File.read!()
    |> Tokenizer.run()
    |> Parser.run()
    |> Eval.run()
  end
end
