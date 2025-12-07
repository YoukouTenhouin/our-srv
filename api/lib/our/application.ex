defmodule Our.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OurWeb.Telemetry,
      Our.Repo,
      {DNSCluster, query: Application.get_env(:our, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Our.PubSub},
      # Start a worker by calling: Our.Worker.start_link(arg)
      # {Our.Worker, arg},
      # Start to serve requests, typically the last entry
      OurWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Our.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OurWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
