do ->
  'use strict'
  Todos.Router.map ->
    @resource 'todos', { path: '/' }, ->
      @route 'active'
      @route 'completed'
      return
    return
  Todos.TodosRoute = Ember.Route.extend(model: ->
    return @store.find 'todo'
  )
  Todos.TodosIndexRoute = Todos.TodosRoute.extend(
    templateName: 'todo-list'
    controllerName: 'todos-list')
  Todos.TodosActiveRoute = Todos.TodosIndexRoute.extend(model: ->
    return @store.filter 'todo', (todo) ->
      return !todo.get('isCompleted')
  )
  Todos.TodosCompletedRoute = Todos.TodosIndexRoute.extend(model: ->
    return @store.filter 'todo', (todo) ->
      return todo.get 'isCompleted'
  )
  return