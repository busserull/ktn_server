defmodule Server.Users do
  use GenServer
  require Logger

  ## Client API
  @doc """
  Starts the server.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Adds a user to the server list.
  Sets the default username of :nil.
  """
  def add_user(client) do
    GenServer.call(__MODULE__, {:add, client})
  end

  @doc """
  Removes a user from the server list.
  """
  def rm_user(client) do
    GenServer.call(__MODULE__, {:rm, client})
  end

  @doc """
  Changes the user name of a 'client'.
  """
  def set_user_name(client, name) do
    GenServer.call(__MODULE__, {:setname, client, name})
  end

  @doc """
  Gets the user name of the 'client'.
  """
  def get_user_name(client) do
    GenServer.call(__MODULE__, {:getname, client})
  end

  @doc """
  Gets a list of all currently connected clients.
  """
  def get_all_clients do
    GenServer.call(__MODULE__, :getallclients)
  end

  @doc """
  Gets a list of all registered user names.
  """
  def get_all_usernames do
    GenServer.call(__MODULE__, :getallusernames)
  end

  ## Callbacks
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:add, client}, _from, names) do
    if Map.has_key?(names, client) do
      {:reply, :ok, names}
    else
      {:ok, {ip, _}} = :inet.peername(client)
      ip = Enum.join(Tuple.to_list(ip), ".")
      Logger.info "New connection: #{ip}"

      names = Map.put(names, client, {ip, :nil})
      {:reply, :ok, names}
    end
  end
  def handle_call({:rm, client}, _from, names) do
    {:ok, {ip, _}} = Map.fetch(names, client)
    Logger.info "Client disconnected: #{ip}"
    names = Map.delete(names, client)
    {:reply, :ok, names}
  end
  def handle_call({:setname, client, name}, _from, names) do

    {:ok, {ip, lastname}} = Map.fetch(names, client)
    names = Map.update!(names, client, fn _ -> {ip, name} end)

    if lastname == :nil do
      Logger.info "New user: #{name}"
    else
      Logger.info "Renamed user: #{lastname} -> #{name}"
    end
    {:reply, :ok, names}
  end
  def handle_call({:getname, client}, _from, names) do
    {:ok, {_ip, name}} = Map.fetch(names, client)
    {:reply, name, names}
  end
  def handle_call(:getallclients, _from, names) do
    {:reply, Map.keys(names), names}
  end
  def handle_call(:getallusernames, _from, names) do
    valueList = Map.values(names)
    usernames = for {_ip, user} <- valueList, do: user
    {:reply, usernames, names}
  end
end
