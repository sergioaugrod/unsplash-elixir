defmodule Unsplash.OAuth do
  use OAuth2.Strategy

  def client do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: Application.get_env(:unsplash, :application_id),
      client_secret: Application.get_env(:unsplash, :application_secret),
      redirect_uri: Application.get_env(:unsplash, :application_redirect_uri),
      site: "https://api.unsplash.com",
      authorize_url: "https://unsplash.com/oauth/authorize",
      token_url: "https://unsplash.com/oauth/token"
    ])
  end

  # Possible scopes.
  # public All public actions (default)
  # read_user Access user’s private data.
  # write_user  Update the user’s profile.
  # read_photos Read private data from the user’s photos.
  # write_photos  Upload photos on the user’s behalf.
  # scope param should be space seperated string, like `scope: "public read_user write_user read_photos write_photos"`
  def authorize_url!(params \\ []) do
    client
    |> OAuth2.Client.authorize_url!(params)
  end

  # Get and store the token
  def authorize!(params \\ [], headers \\ [], options \\ []) do
    client
    |> OAuth2.Client.get_token!(params, headers, options)
    |> store_token
  end

  # Callbacks
  def authorize_url(client, params) do
    client
    |> OAuth2.Strategy.AuthCode.authorize_url(params)
  end

  def get_token(client, params, headers) do
    client
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  # use get_and_update?
  def store_token(token) do
    Agent.update(:unsplash, &Map.put(&1, :token, token))
  end

  defdelegate un_authorize!, to: __MODULE__, as: :remove_token
  def remove_token do
    Agent.update(:unsplash,  &Map.put(&1, :token, nil))
  end

  #Get the Oauth.AccessToken struct from the agent
  def get_access_token do
    Agent.get(:unsplash, &Map.get(&1, :token))
    |> process_token
  end

  #If the token is expired refresh it.
  def process_token(token) when is_map(token) do
    if OAuth2.AccessToken.expired?(token) do
      token = OAuth2.AccessToken.refresh!(token)
      store_token(token)
    end
    token.access_token
  end
  # all other cases
  def process_token(_token), do: nil

end

