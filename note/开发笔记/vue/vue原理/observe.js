// 触发视图更新
function updateView() {
  console.log('更新视图')
}

// 重新定义数组原型
const oldArrayProperty = Array.prototype
// 创建新对象，原型指向oldArrayProperty,在扩展新的方法不会影响原型
const arrProto = Object.create(oldArrayProperty)
['push', 'pop', 'shift', 'unshift', 'splice'].forEach(methodName => {
  arrProto[methodName] = function () {
    updateView() //更新视图
    oldArrayProperty[methodName].call(this, ...arguments)
  }
})

// 重新定义属性，监听起来
function defineReactive(target, key, value) {
  //递归监听
  observer(value)

  // 核心API
  Object.defineProperty(target, key, {
    get() {
      return value
    },
    set(newValue) {
      if (newValue !== value) {
        observer(newValue)
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
  info: {
    address: 'hangzhou'
  },
  nums: [10, 20, 30]
}


// 监听数据
observer(data)

// console.log(data.name)
// data.name = "chitanda-xiaolu"
// data.age = 21
// data.x = '100'
// data.info.address = 'shanghai'
// console.log(data.name)

data.nums.push(40)