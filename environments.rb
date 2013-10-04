configure :development do
  set :show_exceptions, true

  register Sinatra::Reloader
end
