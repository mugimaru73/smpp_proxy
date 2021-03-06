defmodule SmppProxy.CLI do
  @moduledoc ~s"""
  Escript main module with `Optimus` CLI configuration.
  """

  @doc """
  Parses CLI args into `SmppProxy.Config` and starts `SmppProxy.Proxy`.
  """
  def main(args) do
    app_config = optimus_config() |> Optimus.parse!(args)

    if app_config.flags[:debug] do
      Logger.configure(level: :debug)
    end

    SmppProxy.Config.new(app_config.options) |> SmppProxy.Proxy.start_link()
    :timer.sleep(:infinity)
  end

  defp optimus_config do
    Optimus.new!(
      name: "smpp_proxy",
      description: "SMPP 3.4 proxy",
      version: "0.1.0",
      author: "Nikita Babushkin n.babushkin@fun-box.ru",
      allow_unknown_args: false,
      parse_double_dash: true,
      flags: [
        debug: [
          long: "--debug",
          help: "Enables debug logging",
          multiple: false
        ]
      ],
      options: [
        mc_port: [
          short: "-P",
          long: "--mc-port",
          help: "TCP port for proxy MC to listen on",
          parser: :integer,
          default: 5050
        ],
        mc_system_id: [
          short: "-I",
          long: "--mc-id",
          help: "system_id for proxy MC clients",
          required: true
        ],
        mc_password: [
          short: "-W",
          long: "--mc-password",
          help: "password for `mc-id`",
          required: true
        ],
        esme_host: [
          short: "-h",
          long: "--esme-host",
          help: "IP or host of the proxy target",
          default: "localhost"
        ],
        esme_port: [
          short: "-p",
          long: "--esme-port",
          help: "TCP port of the proxy target",
          parser: :integer
        ],
        esme_system_id: [
          short: "-i",
          long: "--esme-id",
          help: "System id to bind to the proxy target",
          required: true
        ],
        esme_password: [
          short: "-w",
          long: "--esme-password",
          help: "Password for `esme-id`",
          required: true
        ],
        senders_whitelist: [
          short: "-S",
          long: "--senders-whitelist",
          help: "Only allow specified senders (submits from source addr / delivers to destination addr)",
          multiple: true
        ],
        receivers_whitelist: [
          short: "-R",
          long: "--receivers-whitelist",
          help: "Only allow specified receivers (submits to destination addr / delivers from destination addr)",
          multiple: true
        ],
        rate_limit: [
          long: "--rate-limit",
          help: "Limits number of outgoing PDU. `10rps` - 10 requests per second; `10rpm` - 10 requests per minute.",
          parser: fn s ->
            case Integer.parse(s) do
              {n, "rps"} ->
                {:ok, {n, :second}}

              {n, "rpm"} ->
                {:ok, {n, :minute}}

              _ ->
                {:error, "Expected values are `*rps` or `*rpm` where `*` is a non negative integer."}
            end
          end
        ]
      ]
    )
  end
end
