defmodule Demo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, plug: Demo.Router, scheme: :http, options: negotiate_cowboy_opts()},
      {Plug.Cowboy.Drainer, refs: :all},
      :systemd.ready()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp negotiate_cowboy_opts() do
    systemd_socket_fds = :systemd.listen_fds()
    to_cowboy_opts(systemd_socket_fds)
  end

  defp to_cowboy_opts([] = _systemd_socket_fds) do
    env_port = System.get_env("PORT") || System.get_env("SHIP_WEB_SERVICE_PORT") || "8000"
    port = String.to_integer(env_port)
    Logger.info("No systemd socket file descriptors found, fallback to listening on #{port}")

    [net: :inet, ip: {127, 0, 0, 1}, port: port]
  end

  # provides Cowboy options for integrating socket-activation of systemd
  defp to_cowboy_opts([socket | _] = _systemd_socket_fds) do
    fd =
      case socket do
        {fd, _name} when is_integer(fd) and fd > 0 -> fd
        fd when is_integer(fd) and fd > 0 -> fd
      end

    Logger.info("systemd socket file descriptors found, try to use #{fd}")

    [net: :inet, port: 0, fd: fd]
  end
end
