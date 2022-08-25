defmodule Tony.Libraries.File do
  def procedures, do: ["write", "read"]

  def read(path) do
    File.read(path)
  end

  def write(path, content) when is_binary(path) and is_binary(path) do
    File.write(path, content)
  end

  def write(_path, _content) do
    ["error", "write: arguments needs be string"]
  end
end
