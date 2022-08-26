defmodule Tony.CLI do
  require Logger

  def main([]), do: IO.puts("Needs a path file")

  def main([path]) do
    case File.read(path) do
      {:ok, content} -> Tony.run(content)
      _ -> IO.puts("File not found: #{path}")
    end
  end
end
