defmodule Server.History do
  @doc """
  Starts the history recorder.
  """
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Stores message to the history log.
  """
  def store_msg(msg) do
    Agent.update(__MODULE__, fn list -> list ++ [msg] end)
  end

  @doc """
  Retrives all messages past.
  """
  def read_log do
    Agent.get(__MODULE__, fn list -> list end)
  end
end
