defmodule OurWeb.FallbackController do
  use Phoenix.Controller, formats: [json: OurWeb.ErrorJSON]

  require Logger

  defp serialize_changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc ->
	String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end)
    |> Enum.map(fn {k, v} -> %{field: k, details: v} end)
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    details = serialize_changeset_error(changeset)
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: OurWeb.ErrorJSON)
    |> render(:error, status: :unprocessable_entity, details: details)
  end

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
