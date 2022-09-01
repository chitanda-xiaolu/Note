// 触发视图更新
function updateView() {
  console.log('更新视图')
}

// 重新定义属性，监听起来
function defineReactive(target, key, value) {
  // 核心API
  Object.defineProperty(target, key, {
    get() {
      return value
    },
    set(newValue) {
      if (newValue !== value) {
        value = newValue
        //更新视图
        updateView()
      }
    }
  })
}

// 监听对象属性
function observer(target) {
  if(typeof target !== 'object' || target === null) {
    return target
  }

  // 重新定义各个属性
  for(let key in target) {
    defineReactive(target, key, target[key])
  }
}

const data = {
  name: 'chitanda',
  age: 20,
  // info: {
  //   address: 'hangzhou'
  // },
  // nums: [10, 20, 30]
}


// 监听数据
observer(data)

console.log(data.name)
data.name = "chitanda-xiaolu"
data.age = 21
data.x = '100'
// delete data.name
console.log(data.name)