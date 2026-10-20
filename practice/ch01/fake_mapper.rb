# 改造前のコード（出発点）
class FakeMapper
  def resources(name, **options)
    only = options[:only]

    puts "GET    /#{name}          → #{name}#index"   if only.nil? || only.include?(:index)
    puts "GET    /#{name}/new      → #{name}#new"     if only.nil? || only.include?(:new)
    puts "POST   /#{name}          → #{name}#create"  if only.nil? || only.include?(:create)
    puts "GET    /#{name}/:id      → #{name}#show"    if only.nil? || only.include?(:show)
    puts "GET    /#{name}/:id/edit → #{name}#edit"    if only.nil? || only.include?(:edit)
    puts "PATCH  /#{name}/:id      → #{name}#update"  if only.nil? || only.include?(:update)
    puts "DELETE /#{name}/:id      → #{name}#destroy" if only.nil? || only.include?(:destroy)
  end

  def draw(&block)
    instance_exec(&block)
  end
end

mapper = FakeMapper.new
mapper.draw do
  resources :users
  resources :posts, only: [:index, :show]
end
