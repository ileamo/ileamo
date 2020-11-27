defmodule Ileamo.Token do
  @salt "Tpqso9IFu36euqqqIsTFJdcTddnG99UTAlmjf96NtWoY15zKjxPcP9pmxnQvXuvD"
  @expiry 86400 * 30


  def sign(conn, data) do
    Phoenix.Token.sign(conn, @salt, data)
  end


  def verify(conn, token, opts \\ []) do
    Phoenix.Token.verify(conn, @salt, token, max_age: Keyword.get(opts, :max_age, @expiry))
  end
end
