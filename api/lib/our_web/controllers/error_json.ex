defmodule OurWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """

  alias Plug.Conn.Status

  def error(%{status: status, message: message}) do
    %{
      error: Status.reason_phrase(Status.code(status)),
      message: message
    }
  end

  def error(%{status: status}) do
    %{error: Status.reason_phrase(Status.code(status))}
  end
end
