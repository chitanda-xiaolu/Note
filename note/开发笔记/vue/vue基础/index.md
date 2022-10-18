#### 插值、指令、动态属性、表达式、v-html

#### 计算属性computted
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

5. **在vue中函数的使用有连个原则**
1. 所有被vue管理的函数，最好写成普通函数，这样this的指向才是vm(vue实例或组件实例对象)
2. 所有不被vue管理的函数(定时器的回调函数、ajax的回调函数等、promise的回调函数)，最好改写成回调函数，
这样this的指向才是vm或数组实例对象。也可以使用变量_this指向this。
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
        // 错误写法
        fullName: () => {
          return this.firstName + ' ' + this.lastName
        }
      },
      watch: {
        // 错误写法
        address (newVal, oldVal) {
          // 定时器为异步操作，回调函数使用普通函数时this指向全局即windose
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



