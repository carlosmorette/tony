defmodule Mix.Tasks.Tony do
  use Mix.Task

  require Logger

  def run([]), do: IO.puts("Needs a path file")

  def run([path]) do
    case File.read(path) do
      {:ok, content} -> Tony.run(content)
      _ -> IO.puts("File not found: #{path}")
    end
  end
end
