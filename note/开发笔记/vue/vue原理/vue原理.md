### 组件化基础
![avatar](https://upload-images.jianshu.io/upload_images/27388007-2a7803ad3c48c738.png)

数据驱动视图(MVVM, setState) ----- Vue React

+ 传统组件，只是静态渲染，更新还是要依赖操作DOM
+ 

### Vue响应式
https://www.jianshu.com/p/c337f9fb477c
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
    }
  }
```

### vdom和diff

### 模板编译

### 渲染过程

### 前端路由
