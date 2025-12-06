defmodule OurWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """

  alias Plug.Conn.Status

  def error(%{status: status} = params) do
    %{
      error: Status.reason_phrase(Status.code(status)),
      message: Map.get(params, :message),
      details: Map.get(params, :details)
    }
  end
end
