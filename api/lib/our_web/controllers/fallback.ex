defmodule OurWeb.FallbackController do
  use Phoenix.Controller, formats: [json: OurWeb.ErrorJSON]

  require Logger

  def call(conn, {:error, status}) do
    conn
    |> put_status(status)
    |> put_view(json: OurWeb.ErrorJSON)
    |> render(:error, status: status)
  end

  def call(conn, {:error, status, message}) do
    conn
    |> put_status(status)
    |> put_view(json: OurWeb.ErrorJSON)
    |> render(:error, status: status, message: message)
  end
end
