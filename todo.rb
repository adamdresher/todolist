# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

# Return an error message if the name is invalid.
# Return nil if the name is valid
helpers do
  def error_for_list_name(name)
    name = name.strip

    if !(1..100).cover? name.size
      'List name must be between 1 and 100 characters.'
    elsif session[:lists].any? { |list| list[:name] == name }
      'List name must be unique.'
    end
  end

  def error_for_todo_name(name)
    name = name.strip

    if !(1..100).cover? name.size
      'Todo must be between 1 and 100 characters.'
    end
  end
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render a new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Create a new list
post '/lists' do
  list_name = params[:list_name]
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    redirect '/lists/new'
  else
    session[:lists] << { name: list_name.strip, todos: [] }
    session[:success] = 'A new list has been added.'
    redirect '/lists'
  end
end

# View a list
get '/lists/:idx' do
  @list_idx = params[:idx].to_i
  @list = session[:lists][@list_idx]

  erb :list, layout: :layout
end

# Render an edit list form
get '/lists/:idx/edit' do
  @list_idx = params[:idx].to_i
  @list = session[:lists][@list_idx]

  erb :edit_list, layout: :layout
end

# Edits a list name
post '/lists/:idx' do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]
  new_name = params[:list_name]
  error = error_for_list_name(new_name)

  if error
    session[:error] = error
    session[:invalid_name] = new_name
    redirect "lists/#{@idx}/edit"
  else
    @list[:name] = new_name.strip
    session[:success] = "A list's name has been changed."
    redirect "/lists/#{@idx}"
  end
end

# Delete a list
post "/lists/:idx/delete" do
  idx = params[:idx].to_i
  session[:lists].delete_at(idx)
  session[:success] = "A list has been deleted."

  redirect '/lists'
end

# Add a todo to the list
post "/lists/:list_idx/todos" do
  @list_idx = params[:list_idx].to_i
  @todo = params[:todo]
  error = error_for_todo_name(@todo)

  if error
    session[:error] = error
    session[:invalid_todo_name] = @todo
  else
    session[:lists][@list_idx][:todos] << { name: @todo.strip, completed: 'false' }
    session[:success] = 'A new todo has been added.'
  end

  redirect "/lists/#{@list_idx}"
end

# Delete a todo from the list
post "/lists/:list_idx/todos/:todo_idx/delete" do
  @list_idx = params[:list_idx].to_i
  @todo_idx = params[:todo_idx].to_i
  session[:lists][@list_idx][:todos].delete_at(@todo_idx)
  session[:success] = "A todo has been deleted."

  redirect "/lists/#{@list_idx}"
end

# Update a todo from the list
post "/lists/:list_idx/todos/:todo_idx/update" do
  @list_idx = params[:list_idx].to_i
  @todo_idx = params[:todo_idx].to_i
  todo = session[:lists][@list_idx][:todos][@todo_idx]
  todo_status = (params[:completed] == 'true')

  todo[:complete] = todo_status
  session[:success] = "A todo has been updated."
  
  redirect "/lists/#{@list_idx}"
end
