router-view是一个路由视图组件，可以用来渲染渲染vue-router对应的组件。
```js
  <template>
    <section class="app-main">
      <transition name="fade-transform" mode="out-in">
        <router-view :key="key" />
      </transition>
    </section>
  </template>

  <script>
  export default {
    name: 'AppMain',
    computed: {
      key() {
        return this.$route.path
      }
    }
  }
  </script>
```
router-view key属性的作用是：
+ **1.** 不设置router-view的key属性
由于Vue会服复用相同组件，即/page/a => /page/b或者/page?id=a => /page?id=b 这类链接跳转时，将
不在执行created,mounted之类的钩子，这时候你需要在路由组件中，添加beforeRouteUpdate钩子来执行
相关方法来拉取数据。
相关钩子加载顺序为：beforeRouteUpdate

+ **2.**设置router-view的key属性值为$router.path
从/page/a => /page/b, 由于这两个路由的$route.path并不一样，所以组件被强制不复用，相关钩子加载
顺序为beforeRouteUpdate => created => mounted
从/page?id=a => /apge?id=b， 由于这两个路由的$route.path一样，所以和设置key属性一样，会复用
组件，相关钩子函数加载顺序为:beforeRouteUpdate

+ **3.**设置router-view的key属性为$route.fullPath
从/page/a => /page/a，由于这连个路由的$route.fullPath并不一样吗，所以组件被强制不复用，相关钩子加载顺序为beforeRouteUpdate => created => mounted

+ **4.** 从/page?id=a => /page?id=b，由于这两个路由的$route.fullPath并不一样，所以组件被强制不复用，相关钩子加载顺序为beforeRouteUpdate => created => mounted