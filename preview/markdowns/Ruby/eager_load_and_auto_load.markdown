As you probably already know, with each `class` is defined, there's a `constant` corresponding to it, named `class name constant`, you will use this constant to reference to that class, for instance:

```ruby
# file a.rb
class A
end

A.new # constant A reference to class A
```

However, in other files, the constant A will not be defined until the file in which the class A be defined, be loaded.

```ruby
# file b.rb
A.new # error: uninitialized constant A (NameError)

# file c.rb
require_relative "./a.rb"
A.new # OK
```

As you can see, if you want to use a class, you have to load it. It's not comfortable in a large/complex project source code where you maybe have to require a ton of classes.

So, there're 2 approaches to solve this problem: `eager load` and `auto load`

## Eager Load 

This term means all needed files will be loaded before hand, once for all.

Suppose i have an app with structure as below

```
app/
|__controllers/
   |__topics_controller.rb
|__models/
   |__topic.rb
app.rb
loader.rb
```

Now in `app.rb`, i want to start `topics_controller` which will load/modify `topic` models, then i can load recurisive all `.rb` files in the `/app` folder:

```ruby
# topic.rb
class Topic
  puts "load topic model"
end

# loader.rb
module Loader
  def eager_load(dir_path)
    walk_through(dir_path) do |name, path|
      require path
    end
  end

  private

  def walk_through(dir_path, &block)
    Dir.foreach(dir_path) do |dof|
      dof_path = File.join(dir_path, dof)
      if dof_path.end_with?(".rb")
        block.call(dof, dof_path)
      elsif File.directory?(dof_path) && !dof.start_with?(".")
        walk_through(dof_path, &block)
      end
    end
  end
end

# app.rb
require_relative "loader"
class Application
  extend Loader
  eager_load(File.join(__dir__,'..','app'))
end

# load topic model
```

As you can see, the class `Topic` is loaded (the text `load topic model` is show on console) although there're any code use it.

Note: `Kernel#require` which will load files only once, it will search your ruby `$LOAD_PATH` to find the required file if the params is not an absolute path, on the other hand, `require_relative` allow you to load file with relative path.

## Auto Load

`Eager load` maybe take a long time when starting the application since it load all needed files at once, the bigger the project the longer time it'll take to eager load.

Here `Auto Load` come to rescue, `Kernel#autoload` is kind of lazy method, it will not load the file until that file be accessed at the first time.

i will add `auto_load` method and expect that with `auto_load`, the `topic` model will be lazy loaded

```ruby
module Loader
  # ...

  def auto_load(dir_path)
    walk_through(dir_path) do |basename, path|
      clazz = basename.split(".").first.capitalize
      autoload clazz, path
    end
  end

  # ...
end

# app.rb
require_relative "loader"
class Application
  extend Loader
  auto_load(File.join(__dir__,'app'))

  def start
    Topic.new
  end
end

app = Application.new # no thing
app.start # load topic model
```

Ok, `Topic` is lazy loaded, but here's still one more interesting, the constant `Topic`.

Let check something

```ruby
# app.rb
require_relative "loader"
class Application
  extend Loader
  auto_load(File.join(__dir__,'..','app'))

  def start
    Topic.new
  end
end

Topic.new # error: uninitialized constant Topic (NameError)
```

Oh !!! turn out the way the constant `Topic` be lazy loaded, is not what i thought, the first time `Topic` is accessed.

Let try something else

```ruby
# app.rb
# ...

Application::Topic.new # uninitialized constant Application::Topic (NameError)
# load topic model
```

What ??? the text `load topic model` appear on console, that mean the constant `Topic` is actually be loaded when there's code reference to `Application::Topic`, not `Topic`, in other words: the constant `Topic` under the loader class `Application`. And the error above mean the constant `Application::Topic` is private constant that `autoload` register it as something like a path which will trigger loading the class `Topic` (using `Kernel::require`).

Let verify that

```ruby
# app.rb
# ...

begin
  Application::Topic.new # error
  # load topic model
ensure
  Topic.new # OK now
  Application::Topic.new # still error
end
```

Yes, that right !

