---
layout: post
title:  "Doubly linked list in Rust"
date:   2022-11-18 20:12:00 -0700
categories: rust
---

Doubly linked list is a linear data structure in which each node holds a reference to the node before and the node after. This is a particularly challenging data structure to implement in Rust (for beginners like me) because the borrow-checker prohibits the kind of trivial solutions that one can implement in higher-level language (like Python) or memory-unsafe language (like C):

```python
class Node:
    def __ini__(self, val):
        self.val = val
        self.prev = None
        self.next = None

class Queue:
    def push(self, new):
        if len(self) == 0:
            # Rust won't allow both self.head and self.tail to own new at the
            # same time
            self.head = self.tail = new
            self.size = 1
        else:
            # After self.tail.next owns "new", you can no longer use new.prev
            self.tail.next = new
            new.prev = self.tail
            self.tail = new
```

As a work around, this implementation takes advantage of the two smart pointers provided by Rust's stadard library:
1. `Rc` is used so that one node can be referenced by the node before it and the node after it
2. `RefCell` is used so that we can mutate the references that a node holds

Before diving into the implementation, let's first define what we expect out of the doubly linked list (or rather, a queue that we will implement using a doubly linked list):

```rust
fn test_queue_push() {
    let mut queue: Queue<i32> = Queue::new();  // []
    queue.push(0);  // [0]
    assert_eq!(queue.peek(), 0);
    assert_eq!(queue.len(), 1);
    queue.push(1);  // [0 <- 1]
    assert_eq!(queue.peek(), 0);
    assert_eq!(queue.len(), 2);
    queue.push(2);  // [0 <- 1 <- 2]
    assert_eq!(queue.peek(), 0);
    assert_eq!(queue.len(), 3);

    assert_eq!(queue.pop(), 0);  // [1 <- 2]
    assert_eq!(queue.len(), 2);
    assert_eq!(queue.peek(), 1);
    assert_eq!(queue.pop(), 1);  // [2]
    assert_eq!(queue.len(), 1);
    assert_eq!(queue.pop(), 2);  // []
    assert_eq!(queue.len(), 0);
}
```

# The `Node` type
Similar to how a singly linked list is defined, the `Node` type will be defined as an enum with a `Nil` indicating an empty node. With this implementation, we will use `Nil` as a sentinel node so that the head node and the tail node has something to point to:

```rust
use std::rc::{Rc, Weak};
use core::cell::RefCell;

enum Node<T: Copy> {
    Nil,
    Cons{
        val: T,
        prev: Weak<RefCell<Node<T>>>,
        next: Rc<RefCell<Node<T>>>,
    },
}
```

There are two things to note of this definition. First, I choose to declare `Node<T>` as an enum instead of a struct out of personal preferences. It is entirely possible to declare the node type as the following, and I could probably do it at another time as an exercise:

```rust
struct Node<T: Copy> {
    val: T,
    // empty references presented using "None"
    prev: Optional<Weak<RefCell<Node<T>>>>,
    next: Optional<Rc<RefCell<Node<T>>>>,
}
```

Second, `prev` is a `Weak` references because in doubly linked list, two neighboring nodes necessarily hold reference to each other, at which time the [circular references](https://doc.rust-lang.org/book/ch15-06-reference-cycles.html) will fail to be automatically dropped, resulting in a memory leak (which the compiler will not be able to detect).

# The `Queue` type
Because unlike the singly linked list, a doubly linked list needs to keep track of both the `head` and the `tail` node, it is impractical to leave the implementation on the node alone. As a result, we need to define a separate `Queue` type

```rust
pub struct Queue<T: Copy> {
    head: Rc<RefCell<Node<T>>>,
    tail: Rc<RefCell<Node<T>>>,
    _len: usize,  // hidden, can only be read using the len() method
    _sentinel: Rc<RefCell<Node<T>>>,  // the one and only sentinel node
}
```

conveniently with the `Queue` type we can also store additional information, such as `_len` to achieve constant time `len()` implementation (with nodes alone we will have to traverse through the entire list to count the number of elements).

A second design choice was to define a unique `sentinel` node for each queue. While it is possible to maintain a unique sentinel node using references of `head` and `tail`, it is a tedious chore that can be very hard to debug. So instead, I chose to keep a reference to the unique sentinel node in each queue.

Pointers can be hard to use. They are hard to use and easy to mess up in C and C++, and they are still hard to use in Rust, although the borrow-checker (whether at compile time or runtime) will make it harder to write bug that blow up at a later time in production (instead of at development). Here are a few things that I found challenging during my implementation

## Mutating references on a node
Mutating references on the node type is actually kind of difficult. Say you have `new: Rc<RefCell<Node<T>>>` and `tail: Rc<RefCell<Node<T>>>`, and you want to set `tail`'s `next` to point to the `RefCell` that `new` points to, and you want the `new`'s prev to point to the `RefCell` that `tail` points to, then you will have to the following:

1. match a mutable reference on `&mut tail` and disregard the `Node::Nil` branch because it is unreachable
2. for the `Node::Cons{ val, prev, next }` branch, take `next: &mut Rc<RefCell<Node<T>>>`
3. dereference `next` and reassign `Rc::clone(&new)` to `*next`
4. Repeat the steps above, but with `tail` and `next` switched, and `Rc::clone` replaced with `Rc::downgrade` because we are working with weak references

This could become very tedious and redundant to implement all by hand. Instead, I chose to implement two methods on `Node` type:

```rust
impl<T: Copy> Node<T> {
    pub fn set_next(&mut self, next: &Rc<RefCell<Node<T>>>) {
        match self {
            Node::Nil => panic!("Setting next on Nil"),
            Node::Cons{ val: _, prev: _, next: selfnext } => {
                *selfnext = Rc::clone(next);
            },
        }
    }

    pub fn set_prev(&mut self, prev: &Rc<RefCell<Node<T>>>) {
        match self {
            Node::Nil => panic!("Setting prev on Nil"),
            Node::Cons{ val: _, prev: selfprev, next: _ } => {
                *selfprev = Rc::downgrade(prev);
            }
        }
    }
}
```

## Extracting reference out of a node
In implementing the branch of `pop()` when `queue.len() > 1`, I need to grab both the `head` and `head.next`, return the value held in head, and mutate the references in `head.next` so that `head.next.prev` points to the sentinel node instead of the old `head`.

`head` has type `Rc<RefCell<Node<T>>>`, so `*head.borrow()` has type `Node<T>`, which we can put in `match` statement. However, this violates the borrow-checker: the value behind deferencing a `Ref` cannot be moved (which we intend to do).

```rust
// compiler error: cannot move out of deference of 'Ref<'_, queue::Node<T>>'
let (output, second) = match *self.head.borrow() {
    Node::Cons{ val, prev: _, next } => {
        (val, Rc::clone(&next))
    },
    _ => unreachable!(),
};
```

Instead we have to borrow the dereferenced value:

```rust
let (output, second) = match &*self.head.borrow() {
    Node::Cons{ 
        val, // &T
        prev: _,  // &Weak<RefCell<Node<T>>>
        next  // &Rc<RefCell<Node<T>>>
    } => {
        (*val, Rc::clone(next))
    },
    _ => unreachable!(),
};
```

## Full implementation
Finally, here is the full implementation

```rust
impl<T: Copy> Queue<T> {
    /// Return an empty queue
    pub fn new() -> Queue<T> {
        let sentinel = Rc::new(RefCell::new(Node::Nil));
        return Queue {
            head: Rc::clone(&sentinel),
            tail: Rc::clone(&sentinel),
            _len: 0,
            _sentinel: sentinel,
        };
    }

    /// Add an element to the tail-end of the queue
    pub fn push(&mut self, val: T) {
        match self._len {
            0 => {  // create new node then set both head and tail to new node
                let new_node = Rc::new(RefCell::new(Node::Cons{
                    val,
                    prev: Rc::downgrade(&self._sentinel),
                    next: Rc::clone(&self._sentinel),
                }));
                self.head = Rc::clone(&new_node);
                self.tail = Rc::clone(&new_node);
                self._len = 1;
            },
            _ => {
                let new_node = Rc::new(RefCell::new(Node::Cons{
                    val,
                    prev: Rc::downgrade(&self.tail),
                    next: Rc::clone(&self._sentinel),
                }));
                self.tail.borrow_mut().set_next(&new_node);
                self.tail = Rc::clone(&new_node);
                self._len += 1;
            }
        }
    }

    /// Pop the head and return (a copy of) the element held
    pub fn pop(&mut self) -> T {
        match self._len {
            0 => panic!("Popping an empty queue!"),
            1 => {
                let output = match *self.head.borrow() {
                    Node::Cons{ val, prev: _, next: _ } => val,
                    _ => unreachable!(),
                };
                let sentinel = Rc::new(RefCell::new(Node::Nil));
                self.head = Rc::clone(&sentinel);
                self.tail = Rc::clone(&sentinel);
                self._len = 0;
                return output;
            },
            _ => {
                let (output, second) = match &*self.head.borrow() {
                    Node::Cons{ val, prev: _, next } => {
                        (*val, Rc::clone(next))
                    },
                    _ => unreachable!(),
                };
                self.head = Rc::clone(&second);
                self.head.borrow_mut().set_prev(&self._sentinel);
                self._len -= 1;
                return output;
            }
        }
    }

    /// Return the number of elements
    pub fn len(&self) -> usize {
        return self._len;
    }

    /// Return a copy of the value held by the head
    pub fn peek(&self) -> T {
        let head = self.head.borrow();
        match &*head {
            Node::Nil => panic!(""),
            Node::Cons{ val, prev: _, next: _ } => *val, 
        }
    }
}
```

# Conclusion
This is a fantastic exercise that reviews `Rc`, `Weak`, `RefCell`, and that helps practice the use of pointers and deferencing. With this exercise done I felt more confident of my knowledge of this chapter of "the book."

And remember kids, **don't roll your own linked list in production**, use the `dequeue` that is already provided in the standard library.

You can find the complete source code [here](https://github.com/xuganyu96/rustlang-the-book/blob/main/15-smart-pointers/src/queue.rs).