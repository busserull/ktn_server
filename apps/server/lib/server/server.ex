defmodule Server do
  require Logger

  @doc """
  Starts accepting connections on given 'port'.
  """
  def accept(port) do
    Server.Users.start_link(Server.Users)
    Server.History.start_link()
    {:ok, socket} = :gen_tcp.listen(port,
      [:binary, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Server.Users.add_user(client)
    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor,
      fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg =
      with  {:ok, data} <- read_line(socket),
            {:ok, map} <- JSON.decode(data),
            %{"request" => req, "content" => con} <- map,
            do: Server.Reply.get(req, con)

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, msg}) do
    :gen_tcp.send(socket, msg)
  end
  defp write_line(socket, {:login, user}) do
    Server.Users.set_user_name(socket, user)
    :gen_tcp.send(socket, Server.Reply.mk_msg("Server", "info",
      "Login successful."))
    log = Server.History.read_log()
    send_history(socket, log)
  end
  defp write_line(socket, {:logout, :nil}) do
    Server.Users.set_user_name(socket, :nil)
    :gen_tcp.send(socket, Server.Reply.mk_msg("Server", "info",
      "Logout successful."))
  end
  defp write_line(socket, {:msg, msg}) do
    msg = Server.Reply.mk_msg(Server.Users.get_user_name(socket),
      "message", msg)
    Server.History.store_msg(msg)
    broadcast(Server.Users.get_all_clients, msg)
  end
  defp write_line(socket, {:names, :nil}) do
    usernames = Server.Users.get_all_usernames
    msg = Enum.join(usernames, ", ")
    :gen_tcp.send(socket, Server.Reply.mk_msg("Server", "info", msg))
  end
  defp write_line(socket, {:help, help}) do
    :gen_tcp.send(socket, Server.Reply.mk_msg("Server", "info", help))
  end
  defp write_line(socket, {:history, :nil}) do
    log = Server.History.read_log()
    send_history(socket, log)
  end
  defp write_line(socket, {:error, :closed}) do
    Server.Users.rm_user(socket)
    exit(:shutdown)
  end
  defp write_line(_socket, _) do
    Logger.info "Unrecognized message."
  end

  defp broadcast([], _) do
    :ok
  end
  defp broadcast([head|tail], msg) do
    :gen_tcp.send(head, msg)
    broadcast(tail, msg)
  end

  defp send_history(socket, log) do
    resp = "[" <> make_json_array(log, "") <> "]"
    msg = Server.Reply.mk_msg("Server", "history", resp)
    :gen_tcp.send(socket, msg)
  end

  defp make_json_array([], acc) do
    acc
  end
  defp make_json_array([head|tail], acc) do
    make_json_array(tail, acc <> "," <> head)
  end
end

  #defp send_history(_socket, []) do
  #  :ok
  #end
  #defp send_history(socket, [head|tail]) do
  #  :gen_tcp.send(socket, head)
  #  send_history(socket, tail)
  #end
  #end
