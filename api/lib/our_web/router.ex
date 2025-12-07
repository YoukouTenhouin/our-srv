defmodule OurWeb.Router do
  use OurWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", OurWeb do
    pipe_through :api

    get "/user/:name", UserController, :show
    post "/user", UserController, :create

    get "/package/:name", PackageController, :show
    post "/package", PackageController, :create
    get "/package", PackageController, :index

    get "/auth/info", AuthController, :info
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
  end


  # Enable LiveDashboard in development
  if Application.compile_env(:our, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: OurWeb.Telemetry
    end
  end
end
