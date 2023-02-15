**vue**中的**transition**是一个动画过渡封装组件。

### Transition Classes
**使用方式：** \<transition组件名 + 过渡类名\>
在进入/离开的过渡中，transition组件有6个过渡类名：
+ **1.** v-enter：定义进入过渡的开始状态。在元素被插入之前生效，在元素被插入之后的下一帧移除。
+ **2.** v-enter-active：定义进入过渡生效时的状态。在整个进入过渡的阶段中应用，在元素被插入之前生效，在过渡/动画完成之后移除。这个类可以被用来定义进入过渡的过程时间，延迟和曲线函数。
+ **3.** v-enter-to：2.1.8 版及以上定义进入过渡的结束状态。在元素被插入之后下一帧生效 (与此同时 v-enter 被移除)，在过渡/动画完成之后移除。
+ **4.** v-leave：定义离开过渡的开始状态。在离开过渡被触发时立刻生效，下一帧被移除。
+ **5.** v-leave-active：定义离开过渡生效时的状态。在整个离开过渡的阶段中应用，在离开过渡被触发时立刻生效，在过渡/动画完成之后移除。这个类可以被用来定义离开过渡的过程时间，延迟和曲线函数。
+ **6.** v-leave-to：2.1.8 版及以上定义离开过渡的结束状态。在离开过渡被触发之后下一帧生效 (与此同时 v-leave 被删除)，在过渡/动画完成之后移除。

```html
    <div id="example-1">
      <button @click="show = !show">
        Toggle render
      </button>
      <transition name="slide-fade">
        <p v-if="show">hello</p>
      </transition>
   </div>
```
```js
  new Vue({
  el: '#example-1',
    data: {
      show: true
    }
  })
```
```css
  /* 可以设置不同的进入和离开动画 */
  /* 设置持续时间和动画函数 */
  .slide-fade-enter-active {
    transition: all .3s ease;
  }
  .slide-fade-leave-active {
    transition: all .8s cubic-bezier(1.0, 0.5, 0.8, 1.0);
  }
  .slide-fade-enter, .slide-fade-leave-to
  /* .slide-fade-leave-active for below version 2.1.8 */ {
    transform: translateX(10px);
    opacity: 0;
  }
```

### CSS Transitions
可以通过以下特性来定义过渡类名
+ enter-class
+ enter-active-class
+ enter-to-class (2.1.8+)
+ leave-class
+ leave-active-class
+ leave-to-class (2.1.8+)

```html
  <link href="https://cdn.jsdelivr.net/npm/animate.css@3.5.1" rel="stylesheet" type="text/css">

  <div id="example-3">
    <button @click="show = !show">
      Toggle render
    </button>
    <transition
      name="custom-classes-transition"
      enter-active-class="animated tada"
      leave-active-class="animated bounceOutRight"
    >
      <p v-if="show">hello</p>
    </transition>
  </div>
```
```js
  new Vue({
  el: '#example-3',
    data: {
      show: true
    }
  })
```