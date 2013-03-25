/* -- Language: Scala -- */
/* -- Colorscheme: Monokai -- */

/* -- slide 1 -- */
def foo(x: Int): Int = 3

def bar(x: Int, y: Int) = x + y

def baz[T](param: T) = param match {
  case One(o)    => o
  case Two(t)    => t
  case Three(th) => th
}

/* hello world no comment */

/* -- slide 2 -- */
/* Why is this cool? */

/* Let's build a list? */
sealed trait List[T]
case class ::[A](x: A, xs: List[A]) extends List[A]
case object Nil extends List[Nothing]

/* -- slide 3 -- */

/* Now this should work */
val x :: y :: rest = List(1,2,3)



