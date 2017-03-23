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
    {:help, help()}
  end
  def get(_, _) do
    {:error, :nil}
  end

  @doc """
  Creates a JSON of the server reply message.
  """
  def mk_msg(sender, response, content) do
    map = %{"timestamp" => get_timestamp(),
            "sender" => sender,
            "response" => response,
            "content" => content}
    {:ok, reply} = JSON.encode(map)
    reply
  end

  defp get_timestamp do
    Time.to_string(Time.utc_now)
  end

  defp help do
    "Available commands: login, logout, names, help"
  end
end

