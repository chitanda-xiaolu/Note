#### 插值、指令、动态属性、表达式、v-html

#### 计算属性computted
计算属性可以设置get() 和 set()

#### 监听属性watch
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
        name (newVal, oldVal) {
          console.log('name', newVal, oldVal)
        },
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