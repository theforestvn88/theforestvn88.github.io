## Ruby Super Key-word

Let take a look at the follow code and guess what'll be printed

~~~ruby
class A
  def hi() puts('A') end
end

module M
  def hi() puts('M') end
end

class B < A
  include M

  def hi() super end
end

puts B.new.hi # ?
~~~

If you are OOP developers then maybe you think that `super` in B will point to A as B is inherited A, right ? 

But Ruby inheritance hierarchy does not the same as other languages, it's [the chain of `Class` instances](https://theforestvn88.github.io/publish/Ruby_on_Rails/ruby_classes_are_objects.html) that are arranged to represent the inheritance hierarchy. And Ruby use that chain as path of the **method lookup** process.

The keyword `super` here is a pointer point to the next `class` on the **method lookup** chain, it does not know about the term `parent` at all, and note that when we `include` a module, that module will be the next class on the chain.

In the above code, the chain look like this:
`B -> M -> A`

So `B.new.hi` will print `M` since `super` point to `M` not `A`.

Now if you change the method `hi` in module B to call `super` like this:

~~~ruby
module M
  def hi() super end
end
~~~

Then `B.new.hi` will print `A`.

The chain of classes inheritance hierarchy is the `method-lookup` in Ruby

Now let module M include another module N

~~~ruby
module N
  def hi() puts('N') end
end

module M
  include N
  def hi() super end
end
~~~

Then what'll be printed ? `N`. Because the chain now is `B < M < N < A`.