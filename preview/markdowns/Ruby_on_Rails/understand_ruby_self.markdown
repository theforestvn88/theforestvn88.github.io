"Almost things in Ruby are objects" (except blocks, methods, condition statements).

## How about `Self`?

`Self` is not object but the "keyword" representing the default object of the current context. 

What's "context"? It's "scope":

- those code which is outside of class/module/method belongs to "main" scope ("global" scope).

- those code which is inside of class/module and outside of method belongs to "singleton class" scope.

- those code which is inside of method belongs to "method" scope, which is receiver of the method.

- those code which is inside of block/lambda/proc belongs to the "closure scope" outside block/lambda/proc 

Another point of view: the "receiver" object.

- "global scope"? or the `main` object is the receiver.

- "singleton scope"? or an instance of `Class` object is the receiver.

- "method scope"? or an instance of `whatever-class` object (that own the method) is the receiver.

- "closure scope"? or the `closure` object outside (close to) block/lambda/proc is the receiver.

Let's dirty hand 

~~~ruby
self # main <-- top-level object

class Demo
  self # Demo <-- "Class object" instantiates this "Demo" object

  def show_me
    self # an instance of Demo which call this method
  end

  def self.show_me
    self # 'Demo' object - an instance of 'Class' object
  end

  def name
    '?'
  end
end

Demo.show_me # Demo <-- 'Demo' object (an instance of 'Class' object)
~~~

Block/Lambda/Proc

```ruby
1.then do |num|
  self # main <-- which close to this block ? <-- closure object 
  Demo.new.then do |demo|
    self # main - closure object still `main`
    demo.show_me # <Demo:0x00005583d29e47c8> <-- demo is receiver so it's 'self' inside 'test' 
  end
end

class L
    def call_lambda(lambda)
      puts self # <L:0x000055dda1825080>
      lambda.(self)
    end
end

L.new.call_lambda(-> that do
    puts that # <L:0x000055dda1825080>
    puts self # main <-- which close to this block ? <-- closure object
end)
```

Define method dynamically

```ruby
class K
    def foo
      # who is the receiver of a message 'let define bar' here ? 
      def self.bar # an instance of K that call 'foo'
        puts 'bar'
      end
    end

    # who is the receiver of a message 'let define bar' here ?
    def self.bar # the K class.
        puts 'BAR'
    end
end
  
k = K.new
k.foo
k.bar # bar
K.bar # BAR
```

class_eval will automatically assign the `class caller` as receiver (`self`) of it's following block

```ruby

Demo.class_eval do
  def name
    '?'
  end
  self.name # "Demo" <-- class_eval assign Demo as self
  name # "Demo" <-- class_eval assign Demo as receiver
end
```

instance_eval will automatically assign the `object caller` as receiver (`self`) of it's following block

```ruby
class T
    $o = Object.new
    $o.instance_eval do
        def x(a = (def y; puts self; end))
            p self
            def z; puts self; end
        end
    end
end

$o.x # <Object:0x00005620af2ff` <-- $o
$o.y # <Object:0x00005620af2ff  <-- $o
$o.z # <Object:0x00005620af2ff  <-- $o
T.new.x # undefined method
T.new.y # undefined method
T.new.z # undefined method
```

How about `class <<` ?

```ruby
class << String
  self   # Class:String
end

class << "test"
  self   # Class:String:0x000055a747147348
end

class << 1.class
  self   # Class:Integer
end

class << 1 # can't define singleton (TypeError)
  self   # cannot reach here
end
```

As you know, whenever module A extend B, all B's instance methods become singleton methods of A, then A become the receiver of those methods, that mean `self` inside those methods is A.

Module `extend self`, as the method name already explain it's purpose, make the module extend itself.
So after a module extend itself, all its methods become its singleton methods, and `self` is that module class.

```ruby

module M
  extend self
  
  def show_me
    self # class/module that extend M
  end
end

M.show_me # the M itself
```

## Conclusion

It's easy to assume that `self` === `caller`, since we naturally have tendency to link `self` to the caller object. For example, You are the caller: `You.do_something`,
then inside `do_something`, it's easy to think that `self` is You, right ?

However, when we see `self` as the `receiver`, then we need to ask 'who is the receiver here ?' inside `do_something`.