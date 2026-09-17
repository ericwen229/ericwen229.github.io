---
layout: post
title: 'Y组合子的推导（Python表示）'
date: 2018-1-20 17:56:23 +0800
categories: programming
---


本文将使用Python语言，以阶乘函数（factorial函数）为例，演示如何推导出Y组合子（的变体Z组合子）。

Y组合子有什么用呢？它提供了一种使用lambda演算实现递归的机制。

先不考虑太多，遵循最简单直接的思路实现一个阶乘函数，可能写出的是这样的一段代码（前提当然是用lambda表达式来写了）：


```python
fact = lambda n: 1 if n < 2 else n * fact(n - 1)
print(fact(4))
```

    24


似乎定义得很优美，也能正常工作，但不容忽视的一个事实是，我们在用`fact`函数定义`fact`函数自己：是因为Python解释器帮我们记住了`fact`这个名字对应这个lambda表达式，我们才能在`fact`函数体内用`fact`这个名字进行递归调用。这很不优美——名字出现的初衷仅仅是为了简写，即出现名字的地方，总能用其对应的lambda表达式去替代，最终得到一个仅由lambda表达式组成的等价的程序。而现在呢，我们似乎不使用名字就定义不了递归函数了。

事实上，也没有那么严重啦。一个解决办法是，在调用`fact`函数的时候，将`fact`函数本身作为一个参数传入：


```python
newFact = lambda f, n: 1 if n < 2 else n * f(f, n - 1)
print(newFact(newFact, 4))
```

    24


问题解决了！只不过…

还能更近一步吗？比如，能不能让调用的形式更自然一些？总是要把自己作为第一个参数传进去，总归是挺怪异的。

先对上述lambda表达式柯里化：


```python
newFact = lambda f: lambda n: 1 if n < 2 else n * f(f)(n - 1)
print(newFact(newFact)(4))

fact = newFact(newFact)
print(fact(4))
```

    24
    24


这样做的好处之一是我们可以分别处理多个参数了，如此一来我们可以如上定义`fact`，它的调用形式才是我们期望的最自然的终极形态。此外，柯里化还有一点好处在于我们处理的所有lambda表达式都将是单参数的，这个好处随后便会派上用场。

现在，我们已经得到了仅使用lambda表达式定义，支持递归且调用形式自然的`fact`函数：


```python
newFact = lambda f: lambda n: 1 if n < 2 else n * f(f)(n - 1)
fact = newFact(newFact)
```

去掉`newFact`这一中间形式，便是如下的定义：


```python
fact = (lambda f: lambda n: 1 if n < 2 else n * f(f)(n - 1)) (lambda f: lambda n: 1 if n < 2 else n * f(f)(n - 1))
```

唔…

计算阶乘的逻辑出现了两次，这是一个不大好的smell。这个问题之所以出现，是因为业务逻辑（计算阶乘）和支持递归所需的代码糅合在了一起。

能不能将两者分离开？重新审视`newFact`，可以发现`f(f)`不属于业务逻辑，是为了支持递归调用而存在的，因此将其提取出来作为参数，以函数调用的形式传入：


```python
newFact = lambda f: (lambda q: lambda n: 1 if n < 2 else n * q(n - 1)) (f(f))
fact = newFact(newFact)
```


    ---------------------------------------------------------------------------

    RuntimeError                              Traceback (most recent call last)

    <ipython-input-6-5f6450378a68> in <module>()
          1 newFact = lambda f: (lambda q: lambda n: 1 if n < 2 else n * q(n - 1)) (f(f))
    ----> 2 fact = newFact(newFact)
    

    <ipython-input-6-5f6450378a68> in <lambda>(f)
    ----> 1 newFact = lambda f: (lambda q: lambda n: 1 if n < 2 else n * q(n - 1)) (f(f))
          2 fact = newFact(newFact)


    ... last 1 frames repeated, from the frame below ...


    <ipython-input-6-5f6450378a68> in <lambda>(f)
    ----> 1 newFact = lambda f: (lambda q: lambda n: 1 if n < 2 else n * q(n - 1)) (f(f))
          2 fact = newFact(newFact)


    RuntimeError: maximum recursion depth exceeded


毫无悬念地爆栈了！！！

爆栈的原因也很简单：`newFact`函数体内是一个函数调用，Python对该调用的参数`f(f)`（实则是`newFact(newFact)`）求值会产生无限递归。事实上，我们希望仅当求阶乘函数进入某个分支（`n >= 2`）时才进行递归调用，因此有必要延迟对`f(f)`的求值。我们已知`f(f)`，即`newFact(newFact)`，其是一个单个参数的lambda表达式（`newFact`形如`lambda f: lambda n: ...`，因此`newFact(newFact)`形如`lambda n: ...`），因此解决方法是用一个lambda表达式将其包裹起来：


```python
newFact = lambda f: (lambda q: lambda n: 1 if n < 2 else n * q(n - 1)) (lambda x: f(f)(x))
fact = newFact(newFact)
print(fact(4))
```

其后便可以更进一步，将求阶乘的业务逻辑提取出来（`coreFact`）：


```python
coreFact = lambda q: lambda n: 1 if n < 2 else n * q(n - 1)
newFact = lambda f: coreFact(lambda x: f(f)(x))
fact = newFact(newFact)
print(fact(4))
```

至此，全部的业务逻辑全部包含在`coreFact`当中了。我们试试看能不能把`coreFact`从终极形态`fact`当中提取出来，首先把`fact`展开：

```Python
fact
newFact(newFact)
(lambda f: coreFact(lambda x: f(f)(x))) (lambda f: coreFact(lambda x: f(f)(x)))
```

再次将`coreFact`提取出来：

```Python
(lambda core: (lambda f: core(lambda x: f(f)(x))) (lambda f: core(lambda x: f(f)(x)))) (coreFact)
```

左侧表达式便是Y组合子了。

```Python
Y = (lambda core: (lambda f: core(lambda x: f(f)(x))) (lambda f: core(lambda x: f(f)(x))))
```

不妨再回顾一下如何使用Y组合子构造`fact`函数：


```python
Y = (lambda core: (lambda f: core(lambda x: f(f)(x))) (lambda f: core(lambda x: f(f)(x))))
coreFact = lambda q: lambda n: 1 if n < 2 else n * q(n - 1)
fact = Y(coreFact)
print(fact(4))
```

Y组合子仿佛有魔力一般，赋予了`coreFact`以递归的能力。

注：写作本文是受[The Why of Y](http://www.dreamsongs.com/Files/WhyOfY.pdf)的启发
