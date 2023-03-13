# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

# Validates for out of range list index and words
def load_list(idx)
  lists_range = session[:lists].size - 1
  list = session[:lists][idx.to_i] if ('0'..lists_range.to_s).include? idx
  return list if list

  session[:error] = "The requested list does not exist."
  redirect "/lists"
end

helpers do
  # Return nil if the name is valid
  def error_for_list_name(name)
    name = name.strip

    if !(1..100).cover? name.size
      'List name must be between 1 and 100 characters.'
    elsif session[:lists].any? { |list| list[:name] == name }
      'List name must be unique.'
    end
  end

  # Return nil if the name is valid
  def error_for_todo_name(name)
    name = name.strip

    if !(1..100).cover? name.size
      'Todo must be between 1 and 100 characters.'
    end
  end

  # Return 1 if no todos found
  def next_todo_id(todos)
    max_id = todos.map { |todo| todo[:id] }.max || 0
    max_id + 1
  end

  def select_todo(todos, id)
    todos.select { |todo| todo[:id] === id }.first
  end

  def total_todos(list)
    list[:todos].size
  end

  def total_todos_remaining(list)
    list[:todos].select { |todo| !todo[:complete] }.size
  end

  def list_class(list)
    'complete' if total_todos(list) > 0 && total_todos_remaining(list).zero?
  end

  def lists_sort_by_incomplete(lists, &block)
    completed_lists, incompleted_lists = lists.partition { |list| list_class(list) }

    incompleted_lists.each { |list| yield list, lists.index(list) }
    completed_lists.each { |list| yield list, lists.index(list) }
  end

  def todos_sort_by_incomplete(todos, &block)
    completed_todos, incompleted_todos = todos.partition { |todo| todo[:complete] }

    incompleted_todos.each { |todo| yield todo }
    completed_todos.each { |todo| yield todo }
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
get '/lists/:list_id' do
  @list_id = params[:list_id]
  @list = load_list(@list_id)

  erb :list, layout: :layout
end

# Render an edit list form
get '/lists/:list_id/edit' do
  @list_id = params[:list_id]
  @list = load_list(@list_id)

  erb :edit_list, layout: :layout
end

# Edits a list name
post '/lists/:list_id' do
  @list_id = params[:list_id]
  @list = load_list(@list_id)
  new_name = params[:list_name]
  error = error_for_list_name(new_name)

  if error
    session[:error] = error
    session[:invalid_name] = new_name
    redirect "lists/#{@list_id}/edit"
  else
    @list[:name] = new_name.strip
    session[:success] = "A list's name has been changed."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a list
post "/lists/:list_id/delete" do
  id = params[:list_id].to_i
  session[:lists].delete_at(id)
  session[:success] = "A list has been deleted."

  if env['HTTP_X_REQUESTED_WITH'] === 'XMLHttpRequest'
    '/lists'
  else
    session[:success] = "A list has been deleted."
    redirect "/lists"
  end
end

# Add a todo to the list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id]
  @list = load_list(@list_id)
  @todo = params[:todo]
  error = error_for_todo_name(@todo)

  if error
    session[:error] = error
    session[:invalid_todo_name] = @todo
  else
    id = next_todo_id(@list[:todos])

    @list[:todos] << { id: id, name: @todo.strip }
    session[:success] = 'A new todo has been added.'
  end

  redirect "/lists/#{@list_id}"
end

# Delete a todo from the list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id]
  @todo_id = params[:todo_id].to_i
  @list = load_list(@list_id)

  todo = select_todo(@list[:todos], @todo_id)
  @list[:todos].delete(todo)

  if env['HTTP_X_REQUESTED_WITH'] === 'XMLHttpRequest'
    status 204
  else
    session[:success] = "A todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Update a todo from the list
post "/lists/:list_id/todos/:todo_id/update" do
  @list_id = params[:list_id]
  @todo_id = params[:todo_id].to_i
  list = load_list(@list_id)

  todo = select_todo(list[:todos], @todo_id)

  todo_status = (params[:complete] == 'true')
  todo[:complete] = todo_status
  session[:success] = "A todo has been updated."
  
  redirect "/lists/#{@list_id}"
end

# Complete all todos from the list
post "/lists/:list_id/todos/complete_all" do
  @list_id = params[:list_id]
  list = load_list(@list_id)

  if list[:todos].any?
    list[:todos].each { |todo| todo[:complete] = true }
    session[:success] = 'All todos have been marked complete.'
  end

  redirect "/lists/#{@list_id}"
end
