defmodule OurWeb.Auth do
  alias Our.Repo
  alias Our.Schemas.User

  def hash_password(password) do
    Argon2.hash_pwd_salt(password)
  end

  def verify_password(%User{} = user, password) do
    Argon2.verify_pass(password, user.password)
  end

  def get_user(id) do
    case Repo.get_by User, id: id do
      nil -> {:error, :invalid}
      user -> {:ok, user}
    end
  end

  defp get_secret_key_base() do
    config = Application.fetch_env!(:our, OurWeb.Auth)
    Keyword.fetch!(config, :secret_key_base)
  end

  @hash_type 1
  @hash :blake2b
  @hash_byte_size 64
  defp do_sign(salt, payload) do
    key = get_secret_key_base()
    key_size = byte_size(key)
    salt_size = byte_size(salt)
    payload_size = byte_size(payload)

    s = :crypto.hash_init(@hash)
    s = :crypto.hash_update(s, <<key_size::big-64, key::binary>>)
    s = :crypto.hash_update(s, <<salt_size::big-64, salt::binary>>)
    s = :crypto.hash_update(s, <<payload_size::big-64, payload::binary>>)
    :crypto.hash_final(s)
  end

  defp do_verify(sign, salt, payload) do
    do_sign(salt, payload) == sign
  end

  defp do_pack_token(sign, payload) do
    <<@hash_type::8, sign::binary, payload::binary>>
  end

  defp do_unpack_token(token) do
    <<type::8, rest::binary>> = token
    case type do
      1 ->
	<<sign::binary-size(@hash_byte_size), payload::binary>> = rest
	{:ok, sign, payload}
      _ ->
	{:error, :invalid}
    end
  end

  def sign(salt, term, opts \\ []) do
    time = Keyword.get(opts, :time, System.os_time(:second))
    maxage = Keyword.get(opts, :maxage, :infinity)
    payload = %{time: time, maxage: maxage, term: term}
    payload = :erlang.term_to_binary(payload)
    sign = do_sign(salt, payload)
    token = do_pack_token(sign, payload)
    Base.url_encode64(token, padding: false)
  end

  def verify(salt, token) do
    with {:ok, token} <- Base.url_decode64(token, padding: false),
	 {:ok, sign, payload} <- do_unpack_token(token),
	 true <- do_verify(sign, salt, payload),
	 payload <- :erlang.binary_to_term(payload),
	 %{time: time, maxage: maxage, term: term} <- payload do
      if System.os_time(:second) > time + maxage do
	{:error, :expired}
      else
	{:ok, term}
      end
    else
      false -> {:error, :invalid}
      :error -> {:error, :invalid}
      error -> error
    end
  end

  @cipher :chacha20
  @cipher_key_size 32
  @cipher_iv_size 16
  defp get_encryption_key() do
    base = get_secret_key_base()
    <<key::binary-size(@cipher_key_size), _::binary>> =
      :crypto.hash(:blake2b, base)
    key
  end

  def encrypt(salt, term, opts \\ []) do
    key = get_encryption_key()
    iv = :crypto.strong_rand_bytes(@cipher_iv_size)
    ciphertext = :crypto.crypto_one_time(
		   @cipher, key, iv,
		   :erlang.term_to_binary(term),
		   encrypt: true
		 )
    sign(salt, %{iv: iv, ciphertext: ciphertext}, opts)
  end

  def decrypt(salt, token) do
    key = get_encryption_key()
    with {:ok, payload} <- verify(salt, token),
	 %{iv: iv, ciphertext: ciphertext} <- payload do
      plaintext = :crypto.crypto_one_time(
		    @cipher, key, iv,
		    ciphertext,
		    encrypt: false
		  )
      {:ok, :erlang.binary_to_term(plaintext)}
    end
  end

  @access_token_salt "access"
  @access_token_maxage 86400 # 1 day
  @refresh_token_salt "refresh"
  @refresh_token_maxage 2592000 # 30 days

  def generate_user_tokens(%User{} = user) do
    auth_token = sign(@access_token_salt,
		      %{type: :access, id: user.id},
		      maxage: @access_token_maxage)
    refresh_token = encrypt(@refresh_token_salt,
			    %{type: :refresh,
			      id: user.id,
			      password: user.password},
			    maxage: @refresh_token_maxage)
    {:ok, auth_token, refresh_token}
  end

  def verify_access_token(token) do
    case verify(@access_token_salt, token) do
      {:ok, %{type: :access, id: id}} -> {:ok, id}
      {:ok, _} -> {:error, :invalid}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify_refresh_token(token) do
    case decrypt(@refresh_token_salt, token) do
      {:ok, %{type: :refresh, id: id, password: password}} ->
	{:ok, id, password}
      {:ok, _} -> {:error, :invalid}
      {:error, reason} -> {:error, reason}
    end
  end

  def user_from_access_token(token) do
    with {:ok, id} <- verify_access_token(token),
	 {:ok, user} <- get_user(id) do
      {:ok, user}
    else
      {:error, _} -> {:error, :unauthorized}
    end
  end

  def user_from_refresh_token(token) do
    with {:ok, id, password} <- verify_refresh_token(token),
	 {:ok, user} <- get_user(id) do
      if user.password == password do
	{:ok, user}
      else
	{:error, :unauthorized}
      end
    else
      {:error, _} -> {:error, :unauthorized}
    end
  end

  def get_token_from_conn(conn) do
    with [<<bearer::binary-size(6), " ", token::binary>>] <-
	   Plug.Conn.get_req_header(conn, "authorization"),
	 true <- String.downcase(bearer) == "bearer" do
      {:ok, token}
    else
      _ ->
	{:error, :unauthorized}
    end
  end
end
