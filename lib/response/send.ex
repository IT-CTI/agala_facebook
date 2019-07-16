defmodule Agala.Provider.Facebook.Helpers.Send do
  @api_version "2.6"

  defp bootstrap(bot) do
    case bot.config() do
      %{bot: ^bot} = bot_params ->
        get_bot_params(bot_params)

      error ->
        error
    end
  end

  defp bootstrap(_bot_, bot_params), do: get_bot_params(bot_params)

  defp get_bot_params(bot_params) do
    {:ok,
     Map.put(bot_params, :private, %{
       http_opts:
         (get_in(bot_params, [:provider_params, :hackney_opts]) || [])
         |> Keyword.put(
           :recv_timeout,
           get_in(bot_params, [:provider_params, :response_timeout]) || 5000
         )
     })}
  end

  def base_url(token, path) do
    "https://graph.facebook.com/v" <> @api_version <> path <> "?access_token=" <> token
  end

  defp body_encode(body) when is_bitstring(body), do: body

  defp body_encode(body) when is_map(body) do
    Map.values(body)
    |> Enum.find(fn
      {:file, _} -> true
      {:file, _, _} -> true
      _ -> false
    end)
    |> case do
      nil ->
        Jason.encode!(body)

      _ ->
        multipart =
          Enum.map(body, fn
            {key, {:file, file, file_name}} ->
              {:file, file, {"form-data", [{:name, to_string(key)}, {:filename, String.replace(file_name, " ", "_")}]}, []}

            {key, {:file, file}} ->
              {:file, file,
               {"form-data", [{:name, to_string(key)}, {:filename, Path.basename(file)}]}, []}

            {key, value} ->
              {to_string(key), Jason.encode!(value)}
          end)

        {:multipart, multipart}
    end
  end

  defp body_encode(_), do: ""

  def perform_request(%Agala.Conn{
        responser: bot,
        response: %{method: method, payload: %{body: body, url_path: url_path} = payload},
        private: private
      }) do
    {:ok, bot_params} =
      case private do
        %{agala_bot_config: agala_bot_config} -> bootstrap(bot, agala_bot_config)
        _res -> bootstrap(bot)
      end

    case HTTPoison.request(
           method,
           base_url(bot_params.provider_params.page_access_token, url_path),
           body_encode(body),
           Map.get(payload, :headers, []),
           Map.get(payload, :http_opts) || Map.get(bot_params.private, :http_opts) || []
         ) do
      {:ok, %HTTPoison.Response{body: body}} -> {:ok, Jason.decode!(body)}
      error -> error
    end
  end

  @spec message(conn :: Agala.Conn.t(), recipient_id :: String.t(), message_params :: map()) ::
          Agala.Conn.t()
  def message(conn, recipient_id, message_params) do
    Map.put(conn, :response, %{
      method: :post,
      payload: %{
        body: %{recipient: %{id: recipient_id}, message: message_params},
        headers: [{"Content-Type", "application/json"}],
        url_path: "/me/messages"
      }
    })
    |> perform_request()
  end

  @spec upload_attachment(
          conn :: Agala.Conn.t(),
          type :: String.t(),
          file :: String.t(),
          file_name :: String.t()
        ) :: Agala.Conn.t()
  def upload_attachment(conn, type, file, file_name) do
    Map.put(conn, :response, %{
      method: :post,
      payload: %{
        body: %{
          message: %{attachment: %{type: type, payload: %{}}},
          filedata: {:file, file, file_name}
        },
        headers: [{"Content-Type", "multipart/form-data"}],
        url_path: "/me/message_attachments"
      }
    })
    |> perform_request()
  end
end
