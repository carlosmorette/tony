defmodule Tony do
  alias Tony.{Parser, Tokenizer}

  def run(input_path) do
    input_path
    |> File.read!()
    |> Tokenizer.run()
    |> Parser.run()
  end
end
