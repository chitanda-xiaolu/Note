### 1. 变量
sass使用$符号来声明变量,sass的变量声明和css的属性声明很像,_和-可以混用
```css
  $highlight-color: #F90
```
使用实例：
```css
  $highlight-color: #F90;
  .selected {
    border: 1px solid $highlight_color;
  }

  //编译后

  .selected {
    border: 1px solid #F90;
  }
```
### 2. 嵌套-nesting
```css
  #content {
    article {
      h1 { color: #333 }
      p { margin-bottom: 1.4em }
    }
    #content aside { background-color: #EEE }
  }

  /* 编译后 */
  #content article h1 { color: #333 }
  #content article p { margin-bottom: 1.4em }
  #content aside { background-color: #EEE }
```

### 3. 嵌套时使用父选择器
sass在解开一个嵌套规则时就会把父选择器（article）通过一个空格连接到子选择器的前边（a）形成（article a和article a :hover）。
```css
  article a {
    color: blue;
    :hover { color: red }
  }

  /* 编译后 
  这意味着color: red这条规则将会被应用到选择器article a :hover，article元素内链接的所有子元素在被hover时都会变成红色。
  */
  article a { color: blue }
  article a :hover { color: red }
```
可以使用&去调用父选择器。
```css
  article a {
    color: blue;
    &:hover { color: red }
  }

  /* 编译后 */
  #content aside {color: red};
  body.ie #content aside { color: green }

  .nav {
    & &-text {
      font-size: 15px
    }
  }

  /* 编译后 */
  .nav .nav-text {
    font-size: 15px
  }
```

### 4. 嵌套属性
出了选择器，属性也可以进行嵌套。
```css
  // 常规的css写法
  body {
    font-family: Helvetica, Arial, sans-serif;
    font-size: 15px;
    font-weight: normal
  }

  // sass属性嵌套写法
  body {
    font: {
      family: Helvetica, Arial, sans-serif;
      size: 15px;
      weight: normal
    }
  }

  // 常规css写法
  nav {
    border-style: solid;
    border-width: 1px;
    border-color: #ccc;
  }

  // sass属性嵌套写法
  nav {
    border: 1px solid #ccc {
    left: 0px;
    right: 0px;
    }
  }
```

### 5. 混合器-mixin
mixin可以理解成用名字定义好的样式，如果你的整个网站中有几处小小的样式类似（例如一致的颜色和字体），那么使用变量来统一处理这种情况是非常不错的选择。

mixin使用@mixin表示定义

```css
  @mixin rounded-corners {
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
  }

  notice {
    background-color: green;
    border: 2px solid #00aa00;
    @include rounded-corners;
  }

  //sass最终生成：
  .notice {
    background-color: green;
    border: 2px solid #00aa00;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
  }
  111
```