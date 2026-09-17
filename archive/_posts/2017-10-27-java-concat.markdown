---
layout: post
title: "初探Java字符串拼接实现"
date: 2017-10-27 16:02:07 +0800
categories: programming
---

注：笔者使用的是Java 8

要在Java中实现字符串拼接，在Java中只需要写

{% highlight Java %}
result = str1 + str2 + str3;
{% endhighlight %}

即可，非常直观，且对于任意数量的字符串都是这样。

然而有这么一种常见的说法，说这样的做法效率其实很低下。因为对于任意数量的字符串拼接，程序只是不断重复两两拼接；而对于两个字符串的拼接，程序会创建一个新的字符串，然后把两个字符串的内容分别拷贝过去。如此一来，产生了很多不必要的创建、销毁对象以及拷贝字符串的开销。效率更高的做法应当是使用`StringBuilder`类：

{% highlight Java %}
result = (new StringBuilder(str1)).append(str2).append(str3).toString();
{% endhighlight %}

**真的是这样吗？**

让我们写一段代码来验证一下：

{% highlight Java %}
public class ConcatTest {
    public static void main(String[] args) {
        String s1 = "hel";
        String s2 = "lo,";
        String s3 = " wo";
        String s4 = "rld";
        String result = s1 + s2 + s3 + s4;
    }
}
{% endhighlight %}

使用JDK自带的javap命令反编译`main`函数得到如下的结果：

```
public static void main(java.lang.String[]);
    Code:
       0: ldc           #2                  // String hel
       2: astore_1
       3: ldc           #3                  // String lo,
       5: astore_2
       6: ldc           #4                  // String  wo
       8: astore_3
       9: ldc           #5                  // String rld
      11: astore        4
      13: new           #6                  // class java/lang/StringBuilder
      16: dup
      17: invokespecial #7                  // Method java/lang/StringBuilder."<init>":()V
      20: aload_1
      21: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      24: aload_2
      25: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      28: aload_3
      29: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      32: aload         4
      34: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      37: invokevirtual #9                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
      40: astore        5
      42: return
```

（左右滑动查看完整代码）

可以看到，通过`+`实现的字符串拼接最终还是被编译成了创建`StringBuilder`对象再不断`append`，上述效率低下的原因是不成立的。

因此，对于程序的编写者来说，**在单个表达式内**进行字符串拼接，使用`+`还是`StringBuilder`是没有效率上的区别的。注意上述结论的前提是**在单个表达式内**：如果是一段时间内不定数量的字符串拼接，不时地需要开辟更大的内存空间，那么使用`StringBuilder`对象确实能有效减少对象创建销毁、字符串拷贝带来的开销。

字符串拼接还有一种手段，那就是使用`String`类的`concat`方法。对于两两拼接，这样的方法是最高效的，然而对于任意数量的字符串的拼接，使用`concat`只能以级联的形式两两进行。该种方法倒是由于文章一开始讲的原因，是效率低下的。

---

<br />

然而，对于**Java的实现者**来说，使用`StringBuilder`实现字符串拼接仍然是**相当低效的**。在单个表达式中，字符串的**数目已经确定**了，那么完全有更高效的办法完成字符串拼接，例如[C#](http://referencesource.microsoft.com/#mscorlib/system/string.cs)中实现的（后文有对代码的介绍，可以不必阅读代码）：

{% highlight C# %}
public static String Concat(params Object[] args) {
    if (args==null) {
        throw new ArgumentNullException("args");
    }
    Contract.Ensures(Contract.Result<String>() != null);
    Contract.EndContractBlock();

    String[] sArgs = new String[args.Length];
    int totalLength=0;
    
    for (int i=0; i<args.Length; i++) {
        object value = args[i];
        sArgs[i] = ((value==null)?(String.Empty):(value.ToString()));
        if (sArgs[i] == null) sArgs[i] = String.Empty; // value.ToString() above could have returned null
        totalLength += sArgs[i].Length;
        // check for overflow
        if (totalLength < 0) {
            throw new OutOfMemoryException();
        }
    }
    return ConcatArray(sArgs, totalLength);
}

private static String ConcatArray(String[] values, int totalLength) {
    String result =  FastAllocateString(totalLength);
    int currPos=0;

    for (int i=0; i<values.Length; i++) {
        Contract.Assert((currPos <= totalLength - values[i].Length), 
                        "[String.ConcatArray](currPos <= totalLength - values[i].Length)");

        FillStringChecked(result, currPos, values[i]);
        currPos+=values[i].Length;
    }

    return result;
}
{% endhighlight %}

其基本思想是统计每个待加字符串的长度，然后按照总长度分配一次内存空间，最后依次将所有字符串拷贝到对应位置即可。如此一来，进行一次字符串拼接仅创建了一个新的字符串，且没有任何多余的内存占用。

让我们再来看看`StringBuilder`的实现。

使用[JD-GUI](http://jd.benow.ca)反编译JRE中的包，查看`StringBuilder`的实现，可以发现：

* `StringBuilder`初始化内存空间是有冗余的，也就是说，其会预先分配稍多一些的内存来减少未来拼接字符串可能导致的内存重新分配；
* 当用完已分配的内存空间后，`StringBuilder`会尝试分配一块约等于当前两倍大的内存空间（不考虑整型溢出的情况，若还是不够，则分配刚刚足够的大小）。

上述两点共同决定了，这样的实现：

* 极可能导致内存占用的冗余；
* 可能导致多次新内存空间的开辟和拷贝。

再次恳请读者注意，这是站在**Java实现者**的角度去说的。对于使用Java的编程者来说，在合适的场景下，`StringBuilder`是好的（例如一个服务器程序，不时接收来自客户端的数据并按要求拼接成一个长字符串）。而对于Java实现者，这个问题意味的是为这么一个表达式生成怎样的代码，那么使用`StringBuilder`其实并不高效。

至于个中原因，也许设计者有其他的考虑，也许仅仅是实现者偷了个懒（像我们写编译原理那个编译器一样），具体不得而知了。

P.S. 这个话题来源于微博用户[@老赵](http://weibo.com/jeffz)发起的讨论
