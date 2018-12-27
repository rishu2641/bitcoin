defmodule BitcoinWeb.DashboardController do
  use BitcoinWeb, :controller

  def index(conn, _params) do
    render(assign(conn,:datapoints,""), "dashboard.html")
  end

  def dashboard(conn,  %{"numWallets" => numWallets,"numTX" => numTX}) do

    numWallets = String.to_integer(numWallets)
    numTX = String.to_integer(numTX)

    datapoints = Bitcoin.main(numWallets,numTX)

    render(assign(conn,:datapoints, datapoints),"dashboard.html")

   end

end
