[TOC]



#### 插值、指令、动态属性、表达式

+ **指令**

  - v-text指令：

    1. 作用：向其所在的节点中渲染文本内容。
    2. 与插值语法的区别：v-text会替换掉节点中的内容，插值语法{{}}则不会

  - v-html指令:

    1. 作用：想指定节点中渲染包含html结构的内容

    2. 与插值语法的区别：

       (1) v-html会替换掉节点中所有内容，插值语法{{}}则不会

       (2) v-html可以识别html结构

    3. 严重注意: v-html有安全性问题

       (1)在网站上动态渲染任意HTML是非常危险的, 容易导致XSS攻击。

       (2)一定要在可以信的内容上使用v-html，永远不要在用户提交的内容上

  - v-clock指令(没有值)：

    1. 本质是一个特殊的html标签属性，Vue实例创建完毕并接管容器后，会删掉v-clock属性。
    2. 使用css配合v-clock可以解决网速慢时页面展示出{{xxx}}的问题。

  - v-onece指令:

    1. v-once所在节点在初次动态渲染后，就被视为静态内容了。
    2. 以后数据的改变不会引起所在结构的更新，可以用于优化性能。

  - v-pre指令:

    1. 跳过其所在节点的编译过程。
    2. 可以利用它跳过:没有使用指令语法，没有使用插值语法的节点会加快编译。

  - 自定义指令：

    1. 定义语法：

       (1) 局部指令

       ```js
       // 以对象形式新建指令
       new Vue({
         directives: {
           directive_name: {
             // 配置对象
             xxx
             xxx
           }
         }
       })

       //以函数形式新建指令
       new Vue({
         drectives() {}
       })
       ```

       （2）全局指令

       ```js
       // 以对象形式新建指令
       Vue.drective(指令名称,配置对象)

       //以函数形式新建指令
       Vue.drective(指令名称,回调函数)
       ```

    2. 配置对象中的钩子函数

       (1) bind 指令与元素绑定成功时调用

       (2) inserted 指令所在元素被插入页面是调用

       (3) update 指令所在模板结构被重新解析时调用

    3. 指令定义时不加v-，但使用时要加v-

    4. 指令名称如果是多个单词，要使用kebab-case命名方式，不要用camelCase命名。

#### 计算属性computed
计算属性可以设置get() 和 set()


#### computed和watch区别
**1. 计算属性computed**
```
  支持缓存，只有依赖数据发生改变，才会重新进行计算；
  不支持异步，当 computed 内有异步操作时无效，无法监听数据的变化；
  computed 属性值会默认走缓存，计算属性是基于它们的响应式依赖进行缓存的。也就是基于 data 中声明过或者父组件传递的 props 中的数据通过计算得到的值；
  如果一个属性是由其他属性计算而来的，这个属性依赖其他属性 是一个多对一或者一对一，一般用computed；
  如果 computed 属性值是函数，那么默认会走 get 方法，函数的返回值就是属性的属性值；在computed中的，属性都有一个get和一个 set 方法，当数据变化时，调用 set 方法；
```
优点：
+ 当改变 data 变量值时，整个应用会重新渲染，vue 会被数据重新渲染到 dom 中。这时，如果我们使用 names ，随着渲染，方法也会被调用，而 computed 不会重新进行计算，从而性能开销比较小。当新的值需要大量计算才能得到，缓存的意义就非常大；

+ 如果computed所依赖的**数据发生变化时，计算属性才会重新计算**，并进行缓存；当改变其他数据时，computed属性并不会重新计算，从而提升性能；

+ 当拿到的值需要进行一定处理使用时，就可以使用 computed；

**2. 监听属性watch**
+ 不支持缓存，数据变化，直接会触发相应的操作；
+ watch 支持一步操作
+ 监听的函数接收两个参数，第一个是**最新的值**；第二个参数是**之前的值**
+ 当一个属性发生变化时，需要执行对应的操作，一对多
+ 监听数据必须是data中声明过或者父组件传递过来的props中的数据。当数据变化时触发其他操作，函数有连个参数：
  immediate: 组件加载立即触发回调函数执行；
  deep: 深度监听；为了发现对象内部的值发生变化，复杂类型的数据时使用，例如：数组中的对象内容的改变，**注意**
  监听数组的变动不需要这么做。注意:deep无法监听到数组的变动和对象的新增，参考vue数组变异，只有以响应式的方式才会被监听到；


1. 当被监听的属性发生变化时，回调函数自动调用，进行相关操作
2. 监听的属性必须存在，才能进行监视
3. 监听的两种写法：
  (1) vew Vue时传入watch配置
  (2) 通过vm.$watch
  ```js
    vm.$watch('data', {
      handler (newVal, oldVal) {
        console.log('data', newVal, oldVal)
      }
    })
  ```
4. 当监听属性是对象时需要需要进行深度监听
```js
  <template>
    <div>
      <input type="text" v-model="name">
      <p>{{ name }}</p>
      <input type="text" v-model="info.hobby">
      <p>{{ info }}</p>
    </div>
  </template>

  <script>
    export default {
      data () {
        return {
          name: 'chitanda',
          info: {
            hobby: 'photography'
          }
        }
      },
      watch: {
        // 监听属性的简写方式 当不需要配置deep等属性时采用简写方式
        name (newVal, oldVal) {
          console.log('name', newVal, oldVal)
        },
        /**
         * #深度监听
         * (1). Vue中的watch默认不监测对象内部值的改变
         * (2). 配置deep:true 可以监测对象内部值改变
         */
        // 监听属性的完成写法
        info: {
          handler (newVal, oldVal) {
            console.log('info', newVal, oldVal)
          },
          deep: true
        }
      }
    }
  </script>
```

5. **在vue中函数的使用有两个原则**

6. 所有被vue管理的函数，最好写成普通函数，这样this的指向才是vm(vue实例或组件实例对象)

7. 所有不被vue管理的函数(定时器的回调函数、ajax的回调函数等、promise的回调函数)，最好改写成箭头函数，这样this的指向才是vm或数组实例对象。也可以使用变量_this指向this。

  **注：箭头函数指向最近作用域的this，如果最近作用域没有this再向外一层一层的找，直到找到最近作用域**

```js
  <script>
    export default {
      data () {
        return {
          firstName: 'Chitanda',
          lastName: 'Eru'
          address: 'hangzhou'
        }
      },
      computed: {
        // 正确写法
        fullName () {
          return this.firstName + ' ' + this.lastName
        }
        // 错误写法 this会指向window
        fullName: () => {
          return this.firstName + ' ' + this.lastName
        }
      },
      watch: {
        // 错误写法
        address (newVal, oldVal) {
          // 定时器为异步操作，回调函数使用普通函数时this指向全局即window
          setTimeout(function() {
            console.log(this.address)
          },1000)
        }

        // 正确写法
        address (newVal, oldVal) {
          // 定时器为异步操作，回调函数使用箭头函数时this指向vue实例
          setTimeout(() => {
            console.log(this.address)
          },1000)
        }

        // 也可以另起变量_this指向this
        address (newVal, oldVal) {
          // 定时器为异步操作，回调函数使用箭头函数时this指向vue实例
          _this = this
          setTimeout(function() => {
            console.log(_this.address)
          },1000)
        }
      }
    }
  </script>
```


**注：当需要在数据变化时执行异步或开销较大的操作时，这个方式是最有用的，这是和computed最大的区别**

**注意事项**
+ watch 中的函数名称必须是所依赖data中的属性名称；
+ watch 中的函数时不要调用的，只要函数所依赖的属性发生了变化那么相对应的函数就会执行；
+ watch 中的函数会有两个参数 一个是新值，一个是旧值；
+ watch 默认情况下无法监听对象的改变，如果需要进行监听则需要进行深度监听 深度监听需要配置handler函数及deep为true。(因为它只会监听对象的地址是否发生了改变，而值是不会监听的)
+ watch 默认情况第一次的时候不会去做监听，如果需要在第一次加载的时候也要去做监听的话需要设置immediate:true
+ watch在特殊情况下是无法监听到数组的变化：
  通过下标来改变数组中的数据
  通过length来改变数组长度
```js
  通过 Vue 实例方法 set 进行设置 $set( target, propertyName/index, value);
  参数：target {Object | Array} ， propertyName/index {string | number}， value {any}

  this.$set(this.arr,0,100);


  通过 splice 来数组清空 $delete( target, propertyName/index )
  参数：target {Object | Array} ， propertyName/index {string | number}

  this.$delete(this.arr,0)
```

#### Class与Style绑定
**对象语法**
绑定的类名为属性名
```html
  <div
  class="static"
  v-bind:class="{ active: isActive, 'text-danger': hasError }"
  ></div>
```

```js
  data: {
    isActive: true,
    hasError: false
  }
```

```html
  <div v-bind:class="classObject"></div>
```

```js
  data: {
    classObject: {
      active: true,
      'text-danger': false
    }
  },
  computed: {
  classObject: function () {
    return {
      active: this.isActive && !this.error,
      'text-danger': this.error && this.error.type === 'fatal'
      }
    }
  }
```

**数组语法**
```html
  <div v-bind:class="[activeClass, errorClass]"></div>
```

```js
  data: {
    activeClass: 'active',
    errorClass: 'text-danger'
  }
```
渲染为:
```html
  <div class="active text-danger"></div>
```

如果你也想根据条件切换列表中的class，可以用三元表达式：
```html
  <div v-bind:class="[isActive ? activeClass : '', errorClass]"></div>

```

#### v-if和v-show

**区别:**

1、v-if在条件切换时，会对标签进行适当的创建和销毁，而v-show则仅在初始化时加载一次，因此v-if的开销相对来说会比v-show大。

2、v-if是惰性的，只有当条件为真时才会真正渲染标签；如果初始条件不为真，则v-if不会去渲染标签。v-show则无论初始条件是否成立，都会渲染标签，它仅仅做的只是简单的CSS（display）切换。

3、使用v-if时，元素可能无法获取到，而使用v-show一定可以获取到

**使用场景:**

1、 v-if适用于不需要频繁切换元素显示和隐藏的情况

2、v-show适用于需要频繁切换元素的显示和隐藏的场景。

#### v-for(列表渲染)
v-for列表循环中使用key的作用:
用唯一标识标记每一个节点，可以高效渲染虚拟DOM树。

+ 1. 虚拟DOM中key的作用：
    key是虚拟DOM对象的标识，当数据发生变化时，Vue会根据【新数据】生成【新的虚拟DOM】,随后Vue进行
    【新虚拟DOM】与【旧虚拟DOM】的差异比较，比较规则如下：

+ 2. 对比规则：
    (1). 旧虚拟DOM中找到了与新虚拟DOM相同的key:
    若虚拟DOM中内容没变，直接使用之前的真是DOM
    若虚拟DOM中内容遍历，则生成新的真是DOM，随后替换掉页面中之前的真实DOM

  (2). 就虚拟DOM未找到与新虚拟DOM相同的key
  创建新的真是DOM，随后渲染到页面

+ 3. 用index作为key可能会引发的问题：
    (1). 若对数据进行：逆序添加、逆序删除等破坏顺序的操作；会产生没有必要的真是DOM更新==>界面效果没有问
    题，但效率低。

  (2). 如果结构中海油包含输入类DOM会产生错误DOM更新 ==> 界面有问题


#### vue事件修饰符
+ 1. prevent: 阻止默认事件(常用)
+ 2. stop: 阻止事件冒泡(常用)
+ 3. once: 事件只触发一次(常用)
+ 4. capture: 使用时间的捕获模式(时间被捕获时调用回调)
+ 5. self: 只有evevt.target是当前操作的元素时才触发
+ 6. passive: 事件的默认行为立即执行，无需等待事件回调执行完毕 

#### vue键盘时间
js dom 常用键盘事件: keyup keydown
+ 1. vue中常用的的按键别名
    回车 => enter
    删除 => delete (捕获退格和删除键)
    退出 => esc
    空格 => space
    换行 => tab（必须配合keydown使用）
    上 => up
    下 => down
    左 => left
    右 => right

```js
  <input type="text" placehoder="按下回车提示输入" @keyup.enter="showInfo">

  methods: {
    showInfo(e) {
      console.log(e.target.value)
    }
  }
```

+ 2.Vue未提供别名的案件，可以使用按键原始的Key值去绑定，但注意要转为小写且单词之间使用_连接
  例如：大小写切换键键名为CapsLock,需要转换为caps-lock进行时间绑定
```js
  <input type="text" placehoder="按下回车提示输入" @keyup.caps-lock="showInfo">

  methods: {
    showInfo(e) {
      console.log(e.target.value)
    }
  }
```

+ 3.系统修饰键(用法特殊):ctrl、alt、shift、mate
  (1) 配合keyup使用：按下修饰键的同时，再按下其他键，随后释放其他键，时间才被促发。
  (2) 配合keydown使用：正常触发事件

+ 4.也可以使用keyCode去指定具体的按键(不推荐)
+ 5.Vue.config.keyCodes.自定义键名 = 键码， 可以去定制按键别名


#### vue监视数据的原理
1. vue会监视data中所有层次的数据。
2. 如果监测对象中的数据？
  通过setter实现监视，且要在new Vue时就传入要监测的数据。
  (1) 对象中后追加的属性，Vue默认不做响应式处理
  (2) 如需给后添加的属性做响应式，使用如下方法
    ```js
    Vue.set(target, propertyName/index, value)
    vm.$set(target, propertyName/index, value)
    ```
3. 如何监测数组中的数据？
  通过setter实现监视，且要new Vue是就传入要监视的数据。
  (1) 调用原生对应的方法对数组进行更新。
  (2) 重新解析模板，进而更新页面。

4. 在Vue修改数组中的某个元素一定要用如下方法：
  (1) 使用这些API：push()、pop()、shift()、unshift()、splice()、sort()、reverse()
  (2) Vue.set()或vm.$set()

特别注意: Vue.set()和vm.$set()不能给vm或vm的根数据对象(data) 添加属性

#### vue收集表单数据
```html
  <input type="text"/>, 则v-model收集的是value值，用户输入的就是value值
  <input type="radio"/>, 则v-model收集的是value值，且要给标签配置value值
  <input type="checkbox"/>
  1. 没有配置input的value属性，那么收集的就是checked(勾选or未勾选，是布尔值)
  2. 配置input的value属性:
  (1) v-model的初始值是非数组，那么收集的就是checked(勾选or未勾选，是布尔值)
  (2) v-model的初始值是数组，那么收集的就是value组成的数组
  备注: v-model的三个修饰符：
  lazy: 失去焦点再收集数据
  number: 输入字符串转为有效的数字
  trim: 输入首位空格过滤
```

#### vue过滤器
定义：对显示的数据进行特定格式化后再显示(适用于一些简单逻辑的处理)
语法：
1. 注册过滤器：Vue.filter(name, callback)或new Vue(filters: {})
2. 使用过滤器: {{ xxx | 过滤器名 }} 或 v-bind:属性 = "xxx | 过滤器名"


备注：

1. 过滤器也可以接收额外参数、多个过滤器也可以串联
2. 并没有改变原本的数据，是产生新的对应数据

#### vue生命周期

1. 又名：生命周期回调函数、声明周期函数、生命周期钩子。
2. 是什么：Vue在关键时刻帮我调用的一些特殊名称的函数。
3. 生命周期函数的名称不可更改，但函数的具体内容是程序员根据需求编写的。
4. 声明周期函数中的this指向vm或组件实例对象。



#### 组件

定义：实现应用中局部功能代码和资源的集合

作用：服用编码，简化项目编码，提高运行效率

关于组件名：

1. 一个单词组成：第一种写法(首字母小写)header; 第二种(首字母大写)Header
2. 多个单词组成：第一种写法(kebab-case命名)user-info;第二种写法(CamelCase命名)User-info

关于组件标签：

1. 第一种写法:<school></school>
2. 第二种写法:<school/> 不适用脚手架时，<school/>会导致后续组件不能渲染



关于VueComponent:

1. Vue组件本质是一个名为VueComponent的构造函数，且不是程序员定义的，是Vue.extend生成的。
2. 我们只需要写<school></school>或<school/>，Vue解析时会帮我们创建组件的实例对象，即Vue帮我们执行的：new VueComponent(options)。



#### 原型链prototype(显式原型)和\_\_proto\_\_(隐式原型)

+ \_\_proto\_\_(隐式原型)是所有对象都有的(包括函数)
+ 普通对象的\_\_proto\_\_指向创建该实例的构造函数的原型对象
+ prototype原型对象里的constructor指向构造函数本身
+ \_\_proto\_\_和prototype都指向原型对象

![https://pic2.zhimg.com/80/v2-e722d5325f7d4215169f1d04296e0f89_720w.webp]()

```js
// 定义一个构造函数
function Demo() {
  this.a = 1
  this.b = 2
}

// 创建一个Demo的实例对象
// 构造函数在创建对象时，将自己的显示原型属性赋值给对象的隐式原型属性
const d = new Demo()

console.log(Demo.prototype) // 显示原型属性
console.log(d.__proto__) // 隐式原型属性

// 通过显示原型属性操作原型对象，追加一个x属性，值为99
Depo.prototype.x = 99 

console.log(d.x) // 99
```

实例的隐式原型属性永远指向自己缔造者的原型对象



#### 组件构造函数VueComponent 和Vue的关系

VueComponent.prototype.\_\_proto\_\_ === Vue.prototype（vue组件构造函数）

为什么要有这个关系：让组件实力对象(vc)可以访问到Vue原型上的属性、方法。



####  render函数

1. vue.js与vue.runtime.xxx.js的区别：

   (1) vue.js是完整版的Vue，包含:核心功能+模板解析器

   (2) vue.runtime.xxx.js是运行版的Vue，只包含：核心功能：没有模板解析器。

2. 因为vue.runtime.xxx.js没有模板解析器，所有不能使用template配置项，需要使用render函数接收到createElement函数去指定具体内容。


#### 脚手架文件结构：

```tree
|---node_modules
|---public
|   |---favicon.ico: 页标图标
|	|___index.html: 主页面
|---src
|   |---assets：存放静态资源
|   |   |___logo.pbg
|   |---component: 存放组件
|	|---|___Helloworld.vue
|	|---App.vue：汇总所有组件
|	|---main.js：入口文件
|--- .gitignore：git版本管制忽略的配置
|--- babel.config.js：babel的配置文件
|--- package.json：应用跑配置文件
|--- README.md：应用描述文件
|--- pacakge-lock.json：包版本控制文件
```

#### 关于不同版本的Vue:

+ vue.js与vue.runtime.xxx.js的区别：

  （1）vue.js最完整的Vue，包含：核心功能+模板解析器

  （2）vue.runtime.xxx.js是运行版本的Vue，只包含：核心功能；没有模板解析器。

+ 因为vue.runtime.xxx.js没有模板解析器，所以不能使用template配置项，需要使用render函数接收到的createElement函数去指定特定内容。

#### ref属性

1. 被用来给元素或子组件注册引用信息

2. 应用在html标签上获取的真是DOM元素，应用在组件标签上是组件实例对象

3. 使用方式：

   打标识：<h1 ref="xxx">...</h1> 或 <header ref="xxx"></header>

   获取：this.$refs.xxx



#### props

功能：让组件接收外部传过来的数据(即父组件向子组件传值)

(1) 传递数据：

```html
<Sidebar name="xxx" :index="1">
```

(2) 接收数据：

```js
// 方式一
props: ['name', 'index']

// 方式二（限制类型）
props:{
  name: String,
  index: Number
}

// 方式三（限制类型、限制必要性、指定默认值）
props:{
  name:{
    type:String,
    required:true,
    default:'item'   
  },
  index:{
    type:Number,
    required:true,  
  }
}
```

props是只读的，Vue底层会监测你对props的修改，如果进行了修改，就会发出警告，若业务需求确实需要修改，如果进行了修改，就会发出警告，若业务确实需要修改，那么请复制props的内容到data中一份，然后去修改data中的数据。

props适用于:

(1)父组件==>子组件 通信

(2)子组件==>父组件 通信(要求父组件先给子组件传递一个函数，然后通过函数将数据已参数的形式传递给父组件)



#### mixin(混入)

可以把多个组件共用的配置提取成一个混入对象

使用方式:

```js
// 第一步定义混入例如:
{
  data() {
    return {....}
  },
  methods: {....}
}

// 第二步使用混入，例如
/*
（1）全局混入：Vue.mixin(xxx)
（2）局部混入：mixins:['xxx'] 
*/
import xxx from ....
//全局混入：Vue.mixin(xxx)
Vue.mixin(xxx)
//局部混入：mixins:['xxx'] 
mixins:['xxx']


```

#### 插件

用于增强Vue

本质：包含install方法的一个对象，install的第一个参数是Vue，第二个以后的参数是插件使用者传递的数据。

定义插件:

```js
// plugins.js
export default {
  install(Vue, x, y, z) {
    // 添加全局过滤器
    Vue.filter(....)

    // 添加全局指令
    Vue.directive(....)

    // 配置全局混入
    Vue.mixin(....)

    // 添加实例方法
    Vue.prototype.$myMethod = function () {...}
    Vue.prototype.$myProperty = xxxx
  }
}
  
// 使用插件:
 import plugins from './plugins'
 Vue.use(plugins)
```

#### webStorage

1. 存储内容大小一般5M左右(不同的浏览器可能不一样)
2. 浏览器端通过Window.sessionStorage和Window.loacalStorage属性来实现本地存储机制
3. 相关API：
   + xxxxStorage.setItem('key',  'value') 这个方法接收一个键和值作为参数，会把键值对添加到存储中，如果键名存在，则更新其对应的值。
   + xxxxStorage.getItem('key_name') 这个方法接受一个键名作为参数，并把键名从存储中删除。
   + xxxxStorage.clear() 这个方法会清空存储中的所有数据。
4. 备注：
   + sessionStorage存储的内容会随着浏览器窗口关闭而消失。
   + LocalStorage存储的内容，需要手动清楚才会消失。
   + xxxxStorage.getItem(xxx)如果xxx对应的value获取不到，那个getItem的返回值是null。
   + JSON.parse(null)的结果依然是null。JSON.stringify()可以将JavaScript对象转换成JSON字符串。



#### 组件的自定义事件

1. 一种组件间通信的方式，适用于：**子组件 ===\> 父组件**

2. 使用场景：A是父组件，B是子组件，B想给A传递数据，那么就要在A中给B绑定自定义事件(事件的回调函数在A中)

3. 绑定自定义事件：

   + 以属性绑定的形式给子组件绑定自定义事件：<child @customFun="callBackFunction"> 或 <child  v-on:trigger="callBackFunction">

     Demo.vue

     ```html
     <Demo>
       <!--
     	使用v-on(@)给子组件绑定自定义事件
     	并给自定义事件指定回调函数
     	-->
       <!-- 方式一 绑定自定义事件 -->
       <child @customFun="callBackFunction" />
       <!-- 方式二 通过操作dom触发自定义事件 -->
       <child ref="child" />
     </Demo>
     ```

     ```js
     export default {
       methods: {
         callBackFunction(prams) {
           console.log(prams)
           console.log("child触发了callBackFunction")
         }
       },
       mounted() {
         this.$refs.student.$on('customFun', this.callBackFunction)
       }
     }
     ```

     Child.vue

     ```html
     <button @click="trigger"></button>
     ```

     ​

     ```js
     export default {
       name: Child,
       methods: {
         trigger() {
           this.$emit('customFun', prams)
         }
       }
     }
     ```

     ​

   + 第二种方式，在父组件中：

     ```js
     <Demo ref="demo">

     ```

4. 触发自定义事件：this.$emit('customFun', 需要传递的参数)

5. 解绑自定义事件this.$off('customFun')

6. 组件上也可以绑定原生DOM事件，需要使用native修饰符。

7. 注意：通过this.\$refs.xxx.\$on('customFun', 回调函数)，回调函数要么配置在methods中，要么用箭头函数，否则this指向会出问题。




#### 全局事件总线（GlobalEventBus）

1. 一种组件间通信的方式，适用于任意组件间通信。

2. 配置全局事件总线：

   ```js
   new Vue({
     ......
     beforeCreate() {
     	Vue.prototype.$bus = this // 配置全局事件总线，$bus就是当前应用的vm实例
     }
   })
   ```

3. 使用事件总线：

   + 接收数据：A组件想接收数据，则在A组件中给$bus绑定自定义事件，事件的回调函数留在A组件自身。（接收数据的组件绑定总线事件）

     ```js
     methods() {
       demo(data) {.....}
     }
     .....
     mounted() {
       this.$bus.$on('xxxx', this.demo)
     }
     ```

   + 提供数据（发送数据的组件触发总线事件）：this.\$bus.\$emit('xxxx', 数据)

4. 最好在beforeDestroy钩子中，用$off去解绑当前组件所用到的时间。



#### 消息订阅与发布(pubsub)

1. 一种组件通信的方式，适用于任意组件通信。

2. 使用步骤：

   + 安装pubsub：```npm i pubsub-js```
   + 引入：```import pubsub from 'pubsub-js'```
   + 接收数据：A组件想接收数据，则在A组件中订阅消息，订阅的回调留在A组件自身。

   ```js
   methods() {
     demo(data) {.....}
   }
   ......
   mounted() {
     this.pid = pubsub.publish('xxx', this.demo) // 订阅消息
   }
   ```

   + 提供数据: ```pubsub.publish('xxx', this.demo)```
   + 最好在beforeDestroy钩子中，用PubSub.unsubscribe(pid)去取消订阅<span style="color:red">取消订阅。</span>


#### $nextTick()

1. 语法：```this.$nextTick(回调函数)```
2. 作用：在下一次DOM更新结束后才执行其指定的回调函数。
3. 什么时候用：当改变数据后，要基于更新后的新DOM进行某些操作时，要在nextTick所指定的回调函数中执行。

#### Vue封装的过渡与动画



#### Vue脚手架配置代理

+ **方法一**

  在vue.config.js中添加如下配置：

  ```js
  devServer: {
    proxy: "http://localhost:5000"
  }

  ```

  1. 优点：配置简单
  2. 缺点：不能配置多个代理，不能灵活控制请求是否走代理。
  3. 工作方式：若按照上述配置代理，当请求了前端不存在资源时，那么该请求会转发给服务器(优先匹配前端资源)

+ 方法二

  编写vue.config.js配置具体代理规则

  ```js
  module.exports = {
    devServer: {
      proxy:｛
        '/api1': {
           target: 'http://localhost:5000', //代理目标的基础路径
           changeOrigin: true,
    	  },
        'api2': {
  	   target: 'http://localhost:5001', //代理目标的基础路径
         changeOrigin: true,
         pathRewrite: {'^/api2':''}
        }
      ｝
    }
  }
  /*
  changeOrigin设置为true时，服务器收到请求头中的host为:localhost:5000
  changeOrigin设置为false时，服务器收到的请求头中的host为:localhost:8080
  changeOrigin默认值为true
  */
  ```

  #### 插槽

  1. 作用：让父组件可以向组件指定位置插图html结构，也是一种组件间的通信方法，适用于父组件===>子组件

  2. 分类：默认插槽、具名插槽、作用域插槽

  3. 使用方式

     + 默认插槽

       ```html
       父组件中：
       <Category>
         <div>html结构</div>
       </Category>
       子组件中(Category)：
       <template>
         <!--定义插槽-->
         <slot>插槽默认内容</slot>
       </template>

       ```

       ​

     + 具名插槽

       ```html
       父组件中:
       <Category>
         <template slot="center">
           <div>html结构1</div>
         </template>
         
         <template v-solot:footer>
           <div>html结构1</div>
         </template>
       </Category>

       子组件中(Category)：
       <template>
         <!--第一插槽-->
         <slot name="center">插槽默认内容</slot>
         <slot name="footer">插槽默认内容</slot>
       </template>
       ```

     + 作用域插槽

       数据在组件的自身，但数据生成需要组件的使用者来决定

       ```html
       父组件中：
       <Category>
         <template scope="scopeData">
           <ul>
             <li v-for="g in scopeData.games" :key="g">{{ g }}</li>
           </ul>
         </template>
       </Category>

       <Category>
         <template slot-scope="scopeData">
           <h4 v-for="g in scopeData.games" :key="g">{{ g }}</h4>
         </template>
       </Category>

       子组件中：
       <template>
         <div>
           <slot :games="games">
         </div>
       </template>
       <script>
         export default {
           name: 'Category',
           props: ['title']
           data() {
             return {
       		games: ['地平线', 'honkai impact']
             }
         	}
         }  
       </script>
       ```

       ​

  #### vuex

  可以简单把vuex理解成一个全局的data，vuex有几个比较核心个概念：State、Getters、Mutation、Action

  Module。![](https://vuex.vuejs.org/vuex.png)

  ​

  + State用于存放全局data
  + Getters相当于组件间可以共享的
  + Mutation用于修改全局data，有Commit触发，无法进行异步操作
  + Action无法直接修改全局data，由dispatch触发，可进行异步操作

  **四个map方法的使用**

  + mapState方法：用于帮助我们映射state中的数据为计算属性

  ```js
  computed: {
    // 借助mapState生成计算属性，sum、school、subject（对象写法）
    ...mapState(sum: 'sum', school: 'school', subject: 'subject')
    
    // 借助mapState生成计算属性，sum、school、subject（数组写法）
    ...mapState('sum')
  }

  ```

  + mapGetters方法：用于帮助我们映射getters中的数据为计算属性

  ```js
  computed: {
    // 借助mapGetters生成计算属性，Sum（对象写法）
    ...mapGetters({Sum: 'Sum'})
    
    // 借助mapGetters生成计算属性，Sum（数组写法）
    ...mapGetters(['Sum'])
  }
  ```

  + mapActions方法：用于帮助我们生成与actions对话的方法，即包含$store.dispatch(xxx)的函数

  ```js
  methods: {
    // 靠mapActions生成：incrementOdd（对象形式）
    ...mapActions({incrementOdd:'sumOdd'})
    
    // 靠mapActions生成，incrementOdd（数组形式）
    ...mapActions(['sumOdd'])
  }

  ```

  ​

  + mapMutations方法：用于帮助我们生成与mutations对话的方法，即：包含$store.commit(xxx)的函数

  ```js
  methods: {
    // 靠mapMutations生成，increment（对象形式）
    ...mapMutations({increment: 'increament'})
    
    // 数组形式
    ...mapMutations(['increment'])
  }
  ```


  ```


  **模块化 命名空间**

  目的：让代码更好维护，让多种数据分类更加明确

  ```js
  const countAbout = {
    namespaced:true, //开启命名空间
    state: {x:1},
    mutations: { ... },
    actions: { ... },
    getters: { 
      bigsum(state){
        return state.sum * 10
      }
    }
  }
                
  const personAbout = {
    namespaced: true, //开启命名空间
    state: { ... },
    mutations: { ... },
    actions: { ... }
  }

  const store = new Vuex.Store({
     modules: {
        countAbout,
        personAbout
    }
  })
  ```

  开启命名空间后，组件读取state数据：

  ```js
  // 方式一：自己直读取
  this.$store.state.personAbout.list

  // 方式二：借助mapState读取
  ...mapGetters('countAbout', ['bigSum'])
  ```

  开启命名空间后，组件中读取getters数据：

  ```js
  // 方式一：自己直接读取
  this.$store.getters['personAbout/firstPersonName']

  // 方式二：借助mapGetters读取
  ...mapGetters('CountAbout', ['bigSum'])
  ```

  开启命名空间后，组件中调用dispatch

  ```js
  // 方式一：自己直接dispatch
  this.$store.dispatch('personAbout/addPerson', person)

  // 方法二：借助mapActions
  ...mapActions('countAbout', ['bigSum'])
  ```

  开启命名空间后，组件中调用commit

  ```js
  // 方式一：自己直接commit
  this.$store.commit('personAbout/addPerson', person)

  // 方式二：借助mapMutations
  ...mapMutations('countAbout', {increament: 'JIA', decrement: 'JIAN'})

  ```



#### vue-router

$route当前组件的路由

$router单页应用的所有路由

路由切换组件会伴随组件生命周期

**带参数的动态路由匹配**

当我们需要将给定匹配模式的路由映射到同一个组件。可以使用带参路由。例如我们有一个user组件，它应该对所有用户进行渲染，但用户ID不同。在Vue Router中

+ query传参

1. 作用：可以简化路由的跳转

2. 如何使用

   - 给路由命名：

     ```js
     {
     	path: '/demo',
        	component: Demo,
         children: [
         	path: 'test',
           	component: Test,
           children: [
             {
               name: 'hello' // 给路由命名
               path: 'welcome',
               component: Hello
             }
           ]
         ]
     }
     ```

     ​

   - 简化跳转

     ```html
     <!--简化前，需要些完成的路径-->
     <router-link to="/demo/test/welcome">跳转</router-link>

     <!--简化后，直接通过名字跳转-->
     <router-link to="/demo/test/welcome">跳转</router-link>

     <!--简化写法配合传递参数-->
     <router-link 
         :to="{
         	name: 'hello',
             query: {
            		name: 'hello'
                 query:｛
              		name: "chitanda"
              	｝
             }
         }"
     >跳转</router-link>

     ```



+ params参数

  配置路由，声明接收params参数

  ```js
  {
    path: '/home',
    component: Home,
    children: [
      {
        path: 'news',
        component:Message,
        children: [
          name: 'detail',
          path: 'detail/:id/:title', // 使用title占位符声明接收params参数
          component: Detail
        ]
      }    
    ]

  }
  ```

  传递参数

  ```html
  <!--跳转并携带params参数，to的字符串写法-->
  <router-link :to="/home/message/detail/233/haha">跳转</router-link>

  <!--跳转并携带params参数，to的字符串写法-->
  <router-link :to="/home/message/detail/233/haha">跳转</router-link>
  ```

  路由携带params参数时，若使用to的对象写法，则不能使用path配置项，必须使用name配置

+ props

  作用：让路由组件更方便的收到参数

```js
{
  name: 'detail',
  path: 'detail/:id', 
  component: Detail,
    
  // 第一种写法：props值为对象，该对象中所有的key-value的最终组合都会通过props传递给Detail组件
  // props: {a:900}
  
  // 第二种写法：props值为布尔值，布尔值为true，则把路由收到的所有params参数通过props传给Detail组件
  // props:true
    
  // 第三种写法：props值为函数，该函数返回的对象中每一组key-value都会通过props传给Detail组件
    props(route) {
      return {
		id: route.query.id
        title: route.query.title
      }
  	}
}
```












