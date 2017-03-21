defmodule Server do
  require Logger

  @doc """
  Starts accepting connections on given 'port'.
  """
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port,
      [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, {ip, _}} = :inet.peername(client)
    ip = Enum.join(Tuple.to_list(ip), ".")
    Logger.info "New connection: #{ip}"

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
  #defp write_line(socket, {:error})
end
