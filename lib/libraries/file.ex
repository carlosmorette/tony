defmodule Tony.Libraries.File do
  @behaviour Tony.Libraries

  @impl true
  def procedures, do: ["write", "read"]

  def read(path) do
    File.read(path)
  end

  def write(path, content) when is_binary(path) and is_binary(path) do
    File.write(path, content)
  end

  def write(_path, _content), do: raise("write: arguments needs be string")
end
