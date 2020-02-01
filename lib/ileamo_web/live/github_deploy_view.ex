defmodule IleamoWeb.GithubDeployView do
  use Phoenix.LiveView

  def render(assigns) do
    IleamoWeb.PageView.render("taldom.html", assigns)
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(Ileamo.PubSub, "mqtt", link: true)
    {:ok, assign(socket, deploy_step: "Ready!")}
  end

  def handle_info(mes, socket) do
    {:noreply, assign(socket, deploy_step: inspect(mes))}
  end
end
