defmodule XLA.Utils do
  @moduledoc false

  @doc """
  Downloads resource at the given URL into `collectable`.

  If collectable raises an error, it is rescued and an error tuple
  is returned.

  ## Options

    * `:headers` - request headers

  """
  @spec download(String.t(), Collectable.t(), keyword()) ::
          {:ok, Collectable.t()} | {:error, String.t()}
  def download(url, collectable, opts \\ []) do
    headers = build_headers(opts[:headers] || [])

    request = {url, headers}
    http_opts = [ssl: http_ssl_opts()]

    caller = self()

    receiver = fn reply_info ->
      request_id = elem(reply_info, 0)

      # Cancel the request if the caller terminates
      if Process.alive?(caller) do
        send(caller, {:http, reply_info})
      else
        :httpc.cancel_request(request_id, :xla)
      end
    end

    opts = [stream: :self, sync: false, receiver: receiver]

    {:ok, request_id} = :httpc.request(:get, request, http_opts, opts, :xla)

    try do
      {acc, collector} = Collectable.into(collectable)

      try do
        download_loop(%{request_id: request_id, acc: acc, collector: collector})
      catch
        kind, reason ->
          collector.(acc, :halt)
          :httpc.cancel_request(request_id, :xla)
          exception = Exception.normalize(kind, reason, __STACKTRACE__)
          {:error, Exception.message(exception)}
      else
        {:ok, state} ->
          acc = state.collector.(state.acc, :done)
          {:ok, acc}

        {:error, message} ->
          collector.(acc, :halt)
          :httpc.cancel_request(request_id, :xla)
          {:error, message}
      end
    catch
      kind, reason ->
        :httpc.cancel_request(request_id, :xla)
        exception = Exception.normalize(kind, reason, __STACKTRACE__)
        {:error, Exception.message(exception)}
    end
  end

  defp build_headers(entries) do
    headers =
      Enum.map(entries, fn {key, value} ->
        {to_charlist(key), to_charlist(value)}
      end)

    [{~c"user-agent", ~c"elixir-nx/xla"} | headers]
  end

  defp download_loop(state) do
    receive do
      {:http, reply_info} when elem(reply_info, 0) == state.request_id ->
        download_receive(state, reply_info)
    end
  end

  defp download_receive(_state, {_, {:error, error}}) do
    {:error, "reason: #{inspect(error)}"}
  end

  defp download_receive(state, {_, {{_, 200, _}, _headers, body}}) do
    acc = state.collector.(state.acc, {:cont, body})
    {:ok, %{state | acc: acc}}
  end

  defp download_receive(_state, {_, {{_, status, _}, _headers, _body}}) do
    {:error, "got HTTP status #{status}"}
  end

  defp download_receive(state, {_, :stream_start, _headers}) do
    download_loop(state)
  end

  defp download_receive(state, {_, :stream, body_part}) do
    acc = state.collector.(state.acc, {:cont, body_part})
    download_loop(%{state | acc: acc})
  end

  defp download_receive(state, {_, :stream_end, _headers}) do
    {:ok, state}
  end

  defp http_ssl_opts() do
    # Use secure options, see https://gist.github.com/jonatanklosko/5e20ca84127f6b31bbe3906498e1a1d7
    [
      cacerts: :public_key.cacerts_get(),
      verify: :verify_peer,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
  end

  @doc false
  def start_inets_profile() do
    # Starting an HTTP client profile allows us to scope the httpc
    # configuration options, such as proxy options
    {:ok, _pid} = :inets.start(:httpc, profile: :xla)
    set_proxy_options()
  end

  @doc false
  def stop_inets_profile() do
    :inets.stop(:httpc, :xla)
  end

  defp set_proxy_options() do
    http_proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
    https_proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")

    no_proxy =
      if no_proxy = System.get_env("NO_PROXY") || System.get_env("no_proxy") do
        no_proxy
        |> String.split(",")
        |> Enum.map(&String.to_charlist/1)
      else
        []
      end

    set_proxy_option(:proxy, http_proxy, no_proxy)
    set_proxy_option(:https_proxy, https_proxy, no_proxy)
  end

  defp set_proxy_option(proxy_scheme, proxy, no_proxy) do
    uri = URI.parse(proxy || "")

    if uri.host && uri.port do
      host = String.to_charlist(uri.host)
      :httpc.set_options([{proxy_scheme, {{host, uri.port}, no_proxy}}], :xla)
    end
  end
end
