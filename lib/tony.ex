defmodule Tony do
  alias Tony.{Eval, Parser, Tokenizer}

  def run(string) do
    string
    |> Tokenizer.run()
    |> Parser.run()
    |> Eval.run()
  end
end
