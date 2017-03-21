defmodule Server.Reply do
  @doc """
  Return a reply to the 'request'/'content' pair given.
  """
  def get("login", user) when user != :nil do
    {:login, user}
  end
  def get("logout", _) do
    {:logout, :nil}
  end
  def get("msg", msg) do
    {:msg, msg}
  end
  def get("names", _) do
    {:names, :nil}
  end
  def get("help", _) do
    {:help, help}
  end
  def get(_, _) do
    {:error, :nil}
  end

  defp help do
    "Available commands: login, logout, names, help"
  end
end

