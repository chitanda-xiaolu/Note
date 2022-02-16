/**
 * 以下快速排序使用填空法，首先将第一个位置的数作为枢纽，start指针和end指针分别指向数组的第一个元素和最后一个元素，然后end指针向前
 * 移动，当遇到比枢纽值小的值或者end值等于start值得时候停止，然后将这个值填入start位置，然后start指针向后移动，当遇到比枢纽值大的
 * 值大的值或者start值等于end值得时候停止，然后将这个值填入end的位置。反复这个过程直到start等于end为止。将一开始的枢纽值填入这个
 * 为止，此时枢纽值左边的值都比枢纽值小，枢纽值右边的值都比枢纽值大。
 */

function quickSort(array, start, end) {
  let length = array.length
  if(!Array.isArray(array) || length <= 1 || start >= end) {return}
  let index = partition(array, start, end)

  quickSort(array, start, index - 1)
  quickSort(array, index + 1, end)

  return array
}

function partition(array, start, end) {
  // 取第一个元素作为枢纽值
  let pivot = array[start]

  // 当start等于end指针时结束循环
  while(start < end) {
    // 当end指向的元素大于枢纽值时，end指针向前移动
    while(array[end] >= pivot && start < end) {
      end--
    }

    // 将比枢纽值小的值填入start所指向的位置
    array[start] = array[end]

    // 当start指向的元素小于枢纽值时，start指针向后移动
    while(array[start] < pivot && start < end) {
      start++
    }

    // 将比枢纽值大的值交换到end位置，进入下一次循环
    array[end] = array[start]
  }

  // 将枢纽值填入中间点
  array[start] = pivot

  // 返回中间索引
  return start

}

l = [6, 1, 5, 2, 4, 3]

console.log(quickSort(l, 0, 5))