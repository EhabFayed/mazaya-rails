# Resolves a download key to its file. Gating: the client-side modal posts a
# lead first; the server also requires the `mz_gate` cookie that
# LeadsController sets, so deep links to gated files still ask for the form.
class DownloadsController < ApplicationController
  def show
    download = site.download(params[:key]) or not_found!
    if download[:gated] && cookies[:mz_gate].blank?
      redirect_to catalog_path(gate: params[:key], anchor: "download")
    else
      redirect_to download[:file], allow_other_host: false
    end
  end
end
