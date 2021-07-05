## Ruby's Classes are Objects

Ruby is considered a pure OOP language, and like other languages, classes in Ruby also play the same role in OOP: blueprints for creating objects. However, in some languages, classes are only a compile-time feature (new classes cannot be declared at run-time), in Ruby, under design concept: "everything is an object in Ruby" , Ruby's classes are objects, they are first-class citizens.

Let's explore how Ruby's classes work internally.

### There is the class `Class`

In object-oriented programming, an object is an instance of a class, in Ruby, all classes are instance of the class name `Class` which actually itself is_a Object.

~~~ruby
Class.is_a? Object # true 
class Foo; end 
Foo.instance_of? Class #true
~~~

As you can see, Foo is an instance of `Class`, an object, and that maybe make you confuse. Just keep in mind that in some languages, classes are pure `abstracts`, in others (like Ruby), classes are pure `objects`.
That why we can say: "everything (almost) is an object in Ruby" (a few things are not objects like blocks, methods and conditional statements).

### Blueprint for creating objects

When a new class is defined (typically using class Name ... end), an object of type `Class` is created, and that object is a prototype for spawning child objects. All the built-in classes, along with the classes you define, have a corresponding global constant with the same name as the class called class name (which only `Class` objects have, normal objects don't have). 

That why when you declare a class with lower-case name, you will get error class/module name must be CONSTANT (in Ruby you cannot define a constant with lower-case name), and that why when you define a class with the name already exists, Ruby will re-open the existing class. Those class names are just constants means that you can treat classes just like any other Ruby objects: use them as arguments in methods, use them in expressions, and use them as references to the real `Class` objects.

~~~ruby
def name_of(a_class) 
  a_class.name 
end 

name_of Foo # Foo 
foo = Foo.new 
name_of foo # NoMethodError

class test # => error: class/module name must be CONSTANT 
end 
~~~

It's easier to work with a `Class` object through its class name, for example instead of working directly with a `Class` object Class:0x1c9f04, we work with its class name Foo.

In many languages, classes are abstract, new instances of a class are created using a special new keyword. In Ruby, classes are objects and the class `Class` itself is an object, so that when we need to create new instance of a class, we send a message new to the `Class` object of that class. As consequence new isn't a keyword, it's a static/class method, no different from any other static/class method, the origin code is something like this: 

~~~ruby
def self.new(*args) 
  obj = allocate 
  obj.initialize(*args)
  obj 
end
~~~

### Call class method

As we said above about class name constants, when we want to create new instance of a class, we will not send new message directly to the `Class` object like `Class:0x1c9f04.new`, instead we call `Foo.new`.

When received new message, a new object is created and saved in a C structure called RObject, the RObject structure contains an inner RBasic structure that has a class pointer called klass -> points to its class. And since classes are object so that each of them also has a klass pointer that points to the `Class` object, and in its turn, the `Class` object has also a klass pointer, but it points to itself.

Picture 1: ruby classes
![ruby class](https://elasticbeanstalk-ap-southeast-1-554663606431.s3-ap-southeast-1.amazonaws.com/ruby_class.jpg "ruby class")

**Note**
When we invoke a method in ruby we are using `single dispatch`. In `single dispatch`, method invocation is done based on a single criteria: class of the object. `double dispatch` dispatching depends on two things: class of the object and the class of the input object. Ruby inherently does not support `double dispatch`. Java which support `double dispatch`. Java supports method overloading which allows two methods with same name to differ only in the type of argument it receives. In ruby we can't have two methods with same name and different signature because the second method would override the first method.

### How those class objects represent the Inheritance Hierarchy

Take a look at [Picture 1] and you will see Ruby classes are lie on a `horizontal` line, not on a `vertical` line as normal `inheritance hierarchy`, in other words, there is not an inheritance hierarchy between classes, all of them are at the same level, are instances of the `Class` and they are chained by pointers `superclass`:

~~~ruby
RubyDev.superclass # Dev 
Dev.superclass # Object 
Object.superclass # BasicObject 
BasicObject.superclass # nil 
~~~

In Ruby, each object contains a reference point to its parent: `superclass`, so an inheritance hierarchy is a chain of superclass pointers. And since each object has only one `superclass pointer` so obviously there is not multiple inheritance in Ruby. However, classes in Ruby can do multiple inheritance by Mixin modules since `Class` is actually a `Module`:

~~~ruby
Class.is_a? Module # true 
Class.ancestors # [Class, Module, Object, Kernel, BasicObject]

module CrazyGuy; end

class RubyDev < Dev 
  include CrazyGuy 
end

me = RubyDev.new 
me.is_a? Dev # true 
me.is_a? CrazyGuy # true 
~~~

The good thing is that the chain of classes are changeable (on fly) and this enable developers re-define it on fly, too.

### Methods lookup & Polymorphism

The chain of superclass pointers is not only represent the Inheritance hierarchy, but also the path of **method lookup** process in Ruby.

An instance of a class doesn't contain methods, it contains only variables, all its methods live in its class and ancestors of that class. When you call a method on that instance, method lookup process will looking for where the method belongs to, first of all, it will search in the class of that instance (kclass pointer) and all modules (if mixin), then if the method not found, the process will go up to the parent class (superclass pointer) and do the same thing, if the method still not found, the process keep go up until it reaches BasicObject.

~~~ruby
class Dev 
  def code; end 
end

class RubyDev < Dev 
  include CrazyGuy 
end 

# the method lookup for `RubyDev.new.code` 
# kclass RubyDev (not found) -> module CrazyGuy (not found) -> superclass Dev (found) 
# Note that, when you mixin modules, the order methods lookup actually like this: 
# [prepend modules -> class itself -> include modules -> append modules] ->[parent class] 
~~~

Look at the path that method lookup process go through, if you want to override a method, what will you do? Put (re-define) that method in front of its recently position in the path of method lookup, right?

~~~ruby
class Dev 
  def code; end 
end

class RubyDev < Dev
  include CrazyGuy 
  #override 
  def code; end 
end 

class JavaDev < Dev 
  include CrazyGuy 
  #override 
  def code; end 
end 

# the method lookup for `RubyDev.new.code` 
# kclass RubyDev (found) .stop here. -> module CrazyGuy -> superclass Dev 
# the method lookup for `JavaDev.new.code` 
# kclass JavaDev (found) .stop here. -> module CrazyGuy -> superclass Dev 
~~~

So RubyDev and JavaDev behave different and that is the `OOP-Polymorphism` we all familiar with, right? In Ruby,we will go further, we can modify classes on fly:

~~~ruby
def add_method 
  def Dev.write_blog 
    "bla ... bla ..." 
  end 
  def JavaDev.write_blog 
    "bla ... (about java) ..." 
  end 
end
add_method # on fly 
RubyDev.write_blog # "bla ... bla ..." 
JavaDev.write_blog # "bla ... (about java) ..." 
~~~

Now the methods lookup path will change, too. We have a special polymorphism, the dynamic polymorphism one.  In Ruby, Python, and many other dynamic programming languages, the ability to dynamically modify a class or module at runtime (affecting only the running instance of the program), is called `monkey patch`. 

The `monkey patch` does not stop here - at classes/modules level, it still continue to instances level.

### Eigenclass & Duck Typing

As noted above, all methods live in classes, all instances of classes only contain variables. So now if we want to do `monkey patch` with a special instance, something like this:

~~~ruby
only_you = RubyDev.new 
not_your_wife = RubyDev.new 
def only_you.monkey_patch 
  true 
end
only_you.monkey_patch # true 
not_your_wife.monkey_patch # NoMethodError 
~~~

How did Ruby do?

One way and another, we must come back to the methods lookup path and find the way to insert the new method into the path, and somehow it only visible for only that special instance. That mean we need insert a class (since methods lookup path is a chain of classes) that is `a-copy-of-that-instance's-class, and only-belongs-to-that-special-instance and also the only one contains the new method`.

In Ruby, that kind of class is called `Eigenclass`. “Eigen” is a German word meaning (roughly) “self,” “own,” “particular to,” or “characteristic of.” Since the `Eigenclass` can exist only in one instance, they each are one and unique, they are officially called the `Singleton` class. (the `Eigenclass` is also called - less commonly - the `Metaclass`, but Ruby’s metaclasses are different from those in languages such as Smalltalk).

Moreover, the problem above is just a specific case of the concept `duck typing`. In a dynamic language such as Ruby, the “type” of an object is not strictly related to its class. Instead, the “type” is simply the set of methods to which an object can respond. Referring to the saying: “if it walks like a duck and quacks like a duck, then it must be a duck”.

In order to do that, in Ruby, the `Eigenclass` solution be applied from the `BasicObject`. That mean all instances of `Object` also have an `Eigenclasses` and of course, all classes (as objects), too. As a consequence, everything as objects in Ruby are able to dynamically transform by modifying its methods, for example, if we keep adding `the Lion` methods into a `Mouse` object, duck typing concept will say: that `Mouse` object is actually a `Lion`. We transformed a `Mouse` into a `Lion` (on fly).

Picture 2: Eigenclasses chain
![Eigenclasses](https://elasticbeanstalk-ap-southeast-1-554663606431.s3-ap-southeast-1.amazonaws.com/eigen_classes_op.jpg "Eigenclasses")

Turn out, the path of method lookup is the chain of Singleton classes, the superclass pointer of a singleton class will point to the parent class's singleton class. Maybe this makes you confuse at first and wonder why Ruby duplicates the chains of classes here (because an eigenclass is just a copy of origin class, right?). Remember that Ruby support `duck typing` that mean a class can born many different duck-type, so it's make sense that the method lookup path must point to the current implementations of super-classes, that mean the chain of singleton-classes.

### Conclusion

So in order to understand Ruby, the first thing we must keep in mind that **In Ruby (almost) everything are objects, classes are objects**.

The way Ruby represents OOP principles is very flexible and also very dangerous, whenever you modify a class you are potentially opening weird edge cases that you can’t possible foresee. But that is Ruby, **Ruby’s philosophy is to give absolute freedom to the programmer, suggesting, but almost never enforcing the way of doing things. It’s the developer’s responsibility to wield this power responsibly**.

### References

- [Ruby Under a Microscope: An Illustrated Guide to Ruby Internals](https://www.amazon.com/Ruby-Under-Microscope-Illustrated-Internals/dp/1593275277)
- [Programming Ruby](https://ruby-doc.com/docs/ProgrammingRuby/)
- [Meta-programming Ruby](https://pragprog.com/titles/ppmetr2/metaprogramming-ruby-2/)



