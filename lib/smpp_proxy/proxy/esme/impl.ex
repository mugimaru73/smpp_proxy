defmodule SmppProxy.Proxy.ESME.Impl do
  @moduledoc """
  An implementation of logic behind proxy ESME session (`SmppProxy.Proxy.ESME.Session`).
  """

  alias SMPPEX.{Pdu, RawPdu, Session}
  alias SmppProxy.{Config, FactoryHelpers}
  alias SmppProxy.Proxy.PduStorage

  @doc """
  Attempts to proxy pdu from MC to ESME.
  """
  @spec handle_pdu_from_mc(Pdu.t() | RawPdu.t(), %{pdu_storage: pid, mc_session: pid, config: Config.t()}) ::
          {:ok, :proxied} | {:error, Pdu.t()}

  def handle_pdu_from_mc(pdu, %{pdu_storage: pdu_storage, mc_session: mc_session, config: config}) do
    if allowed_to_proxy?(pdu, config) do
      PduStorage.store(pdu_storage, pdu)
      Session.send_pdu(mc_session, pdu)

      {:ok, :proxied}
    else
      {:error, FactoryHelpers.build_response_pdu(pdu, 0)}
    end
  end

  @doc "Handles response pdu from MC."
  @spec handle_resp_from_mc(resp_pdu :: Pdu.t(), original_pdu :: Pdu.t(), mc_session :: pid) :: :ok

  def handle_resp_from_mc(pdu, original_pdu, proxy_mc_session) do
    SmppProxy.Proxy.MC.handle_mc_resp(proxy_mc_session, pdu, original_pdu)
  end

  @doc "Handles response pdu from ESME."
  @spec handle_resp_from_esme(pdu :: Pdu.t(), esme_original_pdu :: Pdu.t(), pdu_storage :: pid) :: {:ok, Pdu.t()}

  def handle_resp_from_esme(pdu, esme_original_pdu, pdu_storage) do
    original_pdu = PduStorage.fetch(pdu_storage, esme_original_pdu.ref)
    resp = Pdu.as_reply_to(pdu, original_pdu)
    PduStorage.delete(pdu_storage, original_pdu.ref)

    {:ok, resp}
  end

  defp allowed_to_proxy?(%{mandatory: %{source_addr: source, destination_addr: dest}}, %{
         senders_whitelist: sw,
         receivers_whitelist: rw
       }) do
    (sw == [] || dest in sw) && (rw == [] || source in rw)
  end

  defp allowed_to_proxy?(_pdu, _config), do: true
end
