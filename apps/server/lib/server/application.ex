defmodule Server.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: Server.TaskSupervisor]]),
      #worker(Task, [Server.Users, :start, [Server.Users]]),
      worker(Task, [Server, :accept, [4040]])
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
