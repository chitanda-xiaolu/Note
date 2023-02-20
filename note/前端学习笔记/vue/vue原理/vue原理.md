### 组件化基础
![avatar](https://upload-images.jianshu.io/upload_images/27388007-2a7803ad3c48c738.png)

数据驱动视图(MVVM, setState) ----- Vue React

+ 传统组件，只是静态渲染，更新还是要依赖操作DOM
+ 

### Vue响应式
原理：vue采用数据劫持结合发布者-订阅者模式的方式 来实现数据的响应式，在getter中收集依赖，在setter中触发依赖。
即把用到改数据的地方收集起来，然后等属性发生变化时，把之前收集好的依赖循环触发一遍。

vue2通过Object.defineProperty来劫持数据的setter，getter。获取属性值会触发getter方法，设置属性值会触发setter方法，
在setter方法中调用修改dom的方法来实现视图的更新。

**Object.defineProperty的缺点**
+ 1. 只能劫持对象的属性，因此我们需要对每个对象的每个属性进行遍历，如果属性值也是对象就会需要深度遍历，数据量大时，大量
递归会导致调用栈溢出。(深度监听，需要递归到底，异性计算量大)

+ 2. 不能监听对象新增的属性和删除属性。（需要使用Vue.set Vue.delete进行操作）

+ 3. 无法正确的监听数组的方法，无法监控到数组下标的变化，当直接通过数组下标给数组设置值时arr[4]=2，不能实现响应。

Vue3.0是通过Proxy实现数据双向绑定，Proxy是ES6中新增的一个特性，实现的过程是在目标对象之前设置了一层“拦截”，外界对该对象的访问，都必须先通过这层拦截，因此提供了一种机制，可以对外界的访问进行过滤和改写。

Proxy只需要做一层代理就可以监听统计结构下的所有属性变化，当然对于深层结构，递归还是需要进行的。此外Proxy支持代理数组。缺点是兼容性不好。




https://www.jianshu.com/p/c337f9fb477c
https://juejin.cn/post/6844904067727097864
+ 核心API-Object.defineProperty
+ 如何实现响应式
+ Object.defineProperty的一些缺点(Vue3.0启用Proxy)
+ Proxy兼容性不好，且无法polyfill

![avatar](https://upload-images.jianshu.io/upload_images/20308335-f755c3754fdfdff5.png?imageMogr2/auto-orient/strip|imageView2/2/format/webp)
+ Vue数据双向绑定是通过采用**数据劫持**结合**发布者**-**订阅者**的方式来实现的。通过Object.defineProperty()来劫持各个属性的setter, getter。
修改触发set方法赋值，获取触发get方法取值，在数据变动时发布消息给订阅者，触发相应的回调通过数据劫持发布信息。

Vue主要通过以下4个步骤来实现数据双向绑定的：

实现一个监听器Observer：对数据对象进行遍历，包括子属性对象的属性，利用Object.definProperty()对属性都加上setter和getter。这样的话，给这个对象的
某个值赋值，就会触发setter，那么就能监听到数据变化。

实现一个解析器Complie：解析Vue的模板指令，将模板中的变量都替换成数据，然后初始化渲染页面视图，将每个指令对应的节点绑定更新函数，添加监听数据的订阅者
一旦数据有变动，就收到通知，调用更新函数进行数据更新。

实现一个订阅者Watcher：Watcher订阅者是Observer和Complie之间通信的桥梁，主要任务是订阅Observer中的属性值变化的消息，当收到属性值变化的消息时，触发
解析器Complie中对应的更新函数。

实现一个订阅器Dep：订阅器采用发布-订阅 设计模式，采用收集订阅者Watcher，对监听器Observer和订阅者Watcher进行统一管理。

```js
  var obj = {}
  function defineReactive (data, key, val) {
    Object.defindProperty(data, key, {
      enumerable: true,
      configurable: true,
      get () {
        console.log('你试图访问obj的' + key + '属性')
        return val
      },
      set (newValue) {
        console.log('你试图访问obj的' + key + '属性')
        if (val === newValue) {
          return
        }
        val = newValue
      }
    })
  }

  defineReactive(obj, 'a', 10)
  defineReactive(obj, 'b', 60)
  console.log(obj.a)
  console.log(obj.b)
  obj.b++
  console.log(obj.b)
  // 你试图访问obj的a属性
  // 10
  // 你视图访问obj的b属性
  // 60
  // 你视图访问obj的b属性
  // 你视图访问obj的b属性
  // 你视图访问obj的b属性
  // 61

```
其实核心就是通过Object.definProperty()来实现属性的劫持和监听，那么在设置或者获取的时候我们就可以在get或者set方法里加入其它的触发函数，达到监听数据变动的目的。

**Observer**
它的作用是将一个正常的object转换为每个层级的属性都是响应式的。
![avatar](https://upload-images.jianshu.io/upload_images/20308335-79d4d338b583d5ef.png?imageMogr2/auto-orient/strip|imageView2/2/w/957/format/webp)
我们定义了_ob_属性用来存储定义的Observer实例。通过wakl方法进行当前层属性的遍历并设置为响应式。
```js
  export default calss Observer {
    constructor(value) {
      // 构造函数this不是表示类本身，而是实例
      def (value, '_ob_', this, false)
      console.log("我是Observer构造器", value)
      // Observer类的目的是将一个正常的object转换为每个层级的属性都是响应式的
      if (Array.isArray(value)) {
        Object.setPrototypeOf(value, arrayMethods)
      } else {
        this.walk(value)
      }
    }

    // 遍历
    walk (value) {
      for (let k in value) {
        defineReactive(value, k)
      }
    }

    // 数组的特殊遍历
    observerArray (array) {
      for (let - = 0, 1 = array.length; i < l; i++) {
        Observe(array[i])
      }
    }
  }
```
由于存在对象属性嵌套的情况，所以在遍历每一个属性时，我们需要对其子元素进行设置为响应式的，至此形成多个函数循环调用(递归)。
```js
  export default function defineReactive (data, key, val) {
    if (arguments.length == 2) {
      val = data[key]
    }

    // 子元素进行observe。至此形成递归。这个递归是多个函数循环调用，形成递归。
    let childOb = Observe(val)
    Object.defineProperty(data, key, {
      // 可枚举
      enumerable: true,
      // 可被配置，比如可以被删除delete
      configurable:true,
      get () {
        console.log('你试图访问obj的' + key + '属性')
        return val
      },
      get (newValue) {
        console.log('你视图访问obj的' + key + '属性')
        if (val === newValue) {
          return
        }
        val = newValue
        // 当设置为新值时，这个新值也要被observe
        childOb = Observe(newValue)
      }
    })
  }
```

**数组响应式**
我们都知道Vue实现数据双向绑定通过Object,defineProperty()对数据进行劫持，但是Object.defineProperty()只能对属性进行数据劫持，不能对整个对象进行劫持，同理无法对数组进行劫持。
**Vue框架是通过遍历数组和递归遍历对象，从而达到利用Object.defineProperty()也能对对象和数组(部分方法的操作)进行监听。**Vue的数组响应式是以Array.prototype为原型，创建了一个arrayMethonds对象，使用Object.setPrototypeOf()强制让数组指向arrayMethods对象，使用ObjectsetPrototypeOf()强制让数组指向arrayMethods，这样就可以出发我们在arrayMethods中的改写数组操作方法。
```js
  import { def } from "./utils"
  const arrayPrototype = Array.prototype
  // 以Array。prototype为原型创建arrayMethods对象，并暴露
  export const arrayMethods = Object.create(arrayPrototype)
  // 要被改写的7个数组方法
  const methodsNeedChange = ['push', 'pop', 'shift', 'unshift', 'splice', 'sort', 'reserve']
  methodsNeedChange.forEach(methodName, function () {
    const res = original.apply(this, arguments)
    const arg = [...arguments]
    // 把这个数组身上的_ob_取出来_ob_已经添加了，为什么已经被添加了？
    // 因为数组肯定不是最高层，比如obj.g属性时数组，obj不能是数组
    // 第一次遍历obj这个对象的第一层的时候
    // 已经给g属性(就是这个数组)添加了_ob_属性
    const ob = this._ob_
    let inserted = []

    switch (methodName) {
      case 'push':
      case 'unshift':
        inseted = arg;
        break;
      case 'splice':
        inseted = arg.slice(2)
        break
    }

    if (inserted) {
      ob.observerArray(inserted)
    }
    console.log("进来了")
    
  })

```

### vdom(Virtual DOM)和diff
+ vdom是实现vue和React的重要基石
+ diff算法是vdom中最核心、最关键的部分
+ vdom - 用JS模拟DOM结构计算出最小的变成，操作DOM

### 模板编译

### 渲染过程

### 前端路由
