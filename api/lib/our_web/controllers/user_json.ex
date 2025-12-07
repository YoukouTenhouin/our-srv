defmodule OurWeb.UserJSON do
  alias Our.Schemas.User

  defp data(%User{} = user) do
    %{
      name: user.name,
      profile: user.profile
    }
  end

  def show(%{user: user}) do
    %{data: data(user)}
  end
end
