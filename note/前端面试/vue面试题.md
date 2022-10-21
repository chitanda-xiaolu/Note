### 生命周期函数面试题
#### 1. 什么是vue的声明周期
Vue声明周期是指vue实例对象从创建之初到销毁的过程。
![avatar](https://upload-images.jianshu.io/upload_images/9659657-5a49a6960ec6dd33.jpg)

生命周期钩子函数
1.beforeCreate
```js
  beforeCreate() {
    //还未进行数据代理
    // 此时无法通过vm访问data中的数据，methods中的方法
  }
```

2.created
```js
  created() {
    // 已完成初始化
    // 可以通过vm访问data中的数据，methods中的方法
  }
```

3.beforeMount
```js
  beforeMount() {
    // 页面呈现的是未经Vue编译的DOM页面
    // 所有对DOM的操作，最终都不会起作用
  }
```

4.mounted
```js
  mounted() {
    // 页面呈现的是经Vue编译的DOM页面
    // 对DOM的操作会起作用
  }
```

5.beforeUpdate
```js
  breforeUpdate() {
    // 此时数据已更新，但页面还是旧的
    // 数据与页面不一致
  }
```

6.updated
```js
  updated() {
    // 此时页面和数据都更新了
  }
```

7.beforeDestroyed
```js
  beforeDestroyed() {
    // vm中所有的dta、methods、指令都可以用
    // 在此阶段一般进行：关闭定时器，解除自定义事件等操作
  }
```

8.destroyed
```js
  destroyed() {
    // vm中多有的data、methods、指令都不可用
    // 销毁后自定义事件会失效，但原生DOM事件依然有效
  }
```

#### 2. vue生命周期的作用是什么
Vue声明周期是指vue实例对象从创建之初到销毁的过程。vue的生命周期实际上和浏览器渲染过程是挂钩的

#### 3. 第一次页面加载会触发哪几个钩子函数
beforeCreate, created, beforeMount, mounted

#### 4.简述每个生命周期具体适合哪些场景
beforeCreate：在new一个Vue实例后，只有一些默认的生命周期钩子和默认事件，其他的东西都还没创建。在beforeCreate生命周期执行的时候，data和methods中的数据都还没有初始化。不能在这个阶段使用data中的数据和methods中的方法。

create：data 和 methods 都已经被初始化好了，如果要调用 methods 中的方法，或者操作data中的数据，最早可以在这个阶段中操作。

beforeMount：执行到这个钩子的时候，在内存中已经编译好了模板了，但是还没有挂载到页面中，此时，页面还是旧的。

mounted：执行到这个钩子的时候，就表示Vue实例已经初始化完成了。此时组件脱离了创建阶段，进入到了运行阶段。如果我们想要通过插件操作页面上的DOM节点，最早可以在这个阶段中进行。

beforeUpdate：当执行这个钩子时，页面中的显示的数据还是旧的，data中的数据是更新后的，页面还没有和最新的数据保持同步。

updated：页面显示的数据和data中的数据已经保持同步了，都是最新的。

beforeDestroy：Vue实例从运行阶段进入了销毁阶段，这个时候所有的 data 和 methods，指令，过滤器…都是处于可用状态。还没有真正被销毁。

destroyed：这个时候所有的 data 和 methods，指令，过滤器…都是处于不可用状态。组件已经被销毁了。

#### 5.created和mounted的区别
在created阶段，对浏览器来说，渲染整个HTML文档时,dom节点、css规则树与js文件被解析后，但是没有进入被浏览器render过程，上述资源是尚未挂载在页面上，也就是在vue生命周期中对应的created
阶段，实例已经被初始化，但是还没有挂载至$el上，所以我们无法获取到对应的节点，但是此时我们是可以获取到vue中data与methods中的数据的

在mounted阶段，对浏览器来说，已经完成了dom与css规则树的render，并完成对render tree进行了布局，而浏览器收到这一指令，调用渲染器的paint（）在屏幕上显示，而对于vue来说，在mounted阶段，vue的template成功挂载在$el中，此时一个完整的页面已经能够显示在浏览器中，所以在这个阶段，即可以调用节点了（关于这一点，在笔者测试中，在mounted方法中打断点然后run，依旧能够在浏览器中看到整体的页面）。



#### 6.vue获取数据在哪个周期函数
一般 created / beforeMount / mounted 皆可。

#### 7.请详细说明你对vue生命周期的理解？

### vue路由面试题

#### 1.mvvm框架是什么？
+ View是试图层，也就是用户界面。前端主要由HTML和CSS构成。
+ Model是指数据模型，泛指后端进行的各种业务逻辑处理和数据操控，主要围绕数据库系统展现。
+ ViewModel由前端开发人员组织生成和维护的视图数据层。在这一层，前端开发者从后端获取
  得到Model数据进行转换出来，做二次封装，以生成符合View层使用预期的视图数据模型。视图状
  态和行为都封装在ViewModel里。这样的封装使得ViewModel可以完整地去描述View层。
#### 2.vue-router是什么？它有哪些组件
是vue的一个路由插件，router-link router-view
#### 3.active-class是哪些组件的属性？

#### 4.怎么定义vue-router的动态路由？怎么获取传过来的值？

#### 5.vue-router有哪几种导航钩子

#### 6.$route和$router的区别

#### 7.vue-router响应路由参数的变化

#### 8.vue-router传参

#### 9.vue-router的两种模式

#### 10.vue-router实现路由懒加载(动态路由)

### Vue常见面试题

#### 1.vue优点

#### 2.vue组组件向子组件传递数据？

#### 3.子组件向福组件传递事件

#### 4.v-show和v-if指令的共同点和不同点

#### 5.如何让CSS只在当前组件中起作用

#### 6.<keep-alive></keep-alive>的作用是什么？

#### 7.如果获取dom

#### 8.说出几种vue当中的指令和它的用法

#### 9.vue-loader是什么？使用它的用途有哪些？

#### 10.为什么使用key


