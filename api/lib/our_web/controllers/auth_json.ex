defmodule OurWeb.AuthJSON do
  def token(%{auth_token: auth_token, refresh_token: refresh_token}) do
    %{auth_token: auth_token, refresh_token: refresh_token}
  end
end
