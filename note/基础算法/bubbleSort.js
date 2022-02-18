/**
 * 基本思路，使用两层循环两两比较数组内的相邻元素，如果第一个比第二个大，就交换它们
 * @param {Array} array 
 */

function bubbleSort(array) {
  let length = array.length
  if(!Array.isArray(array) || length <= 1) {return}
  for(let i = 0; i < length - 1; i++) {
    for(let j = i + 1; j < length; j++) {
      if(array[i] > array[j]) {
        swap(array, i, j)
      }
    }
  }
  return array
}

function swap(array, i, j) {
  // let temp = array[i]
  // array[i] = array[j]
  // array[j] = temp
  [array[i], array[j]] = [array[j], array[i]]
}
// 可以使用ES6语法优化swap函数
/**
 * function swap(array, i, j) {
 *    [array[i], array[j]] = [array[j], array[i]]
 * }
 */

/**
 * 优化方案1：
 * 1. 外层循环，从最大值开始递减，因为内层是两两比较，因此最外层当outer>=2时即可停止
 * 2. 内层是两两比较，从0开始，比较下标为inner与inner+1，因此，临界条件是inner<outer-1
 * @param {Array} array 
 */
function bubbleSort(array) {
  let length = array.length
  for(let outer = length; outer >= 2; outer--) {
    for(let inner = 0; inner <= outer -1; inner++) {
      if(array[inner] > array[inner + 1]) {
        [array[inner], array[inner + 1]] = [array[inner +1 ], array[inner]]
      }
    }
  }

  return array
}

/**
 * 优化方案2：
 * 一是外层循环优化，我们可以记录当前循环中是否发生了交换，如果没有发生交换则说明没有发生交换，则
 * 说明该序列已经为有序序列了。因此我们不需要再执行之后的外层循环。
 * 
 * 二是内层循环优化，我们可以记录当前循环中最后一次元素交换的位置，该位置以后的序列都是已排好的序列，
 * 因此下一轮循环中无需再去比较。
 */

function bubbleSort(array) {
  if(!Array.isArray(array) || array.length <= 1) {return}
  let lastIndex = array.length -1

  while(lastIndex > 0) {
    let flag = true, k = lastIndex
    for(let j = 0; j < k; j++) {
      if(array[j] > array[j+1]) {
        flag=false
        lastIndex = j
        [array[j], array[j+1]] = [array[j+1], array[j]]
      }
    }

    if(flag) {break}
  }
}

l = [7, 1, 6, 4, 2, 5, 3]
console.log(bubbleSort(l))