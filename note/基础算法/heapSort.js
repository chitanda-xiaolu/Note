/**
 * 堆排序的基本思想是：将待排序序列构成一个大顶堆，此时，整个序列的最大值就是堆顶的根节点。将其与末尾元素
 * 进行交换，此时末尾就为最大值。然后将剩余n-1个元素重新构造成一个堆，这样会得到n个元素的次小值。如此反复
 * 执行，便能得到一个有序序列了。
 * 堆排序的步骤：
 * 1. 创建顶堆(大顶堆或小顶堆)，一般升序采用大顶堆，降序采用小顶堆。
 *    大顶堆： arr[i] >= arr[2i+1] && arr[i] >= arr[2i+2]
 *    小顶堆： arr[i] <= arr[2i+1] && arr[i] <= arr[2i+2]
 * 2. 进行堆排序(此处以使用大顶堆对数组进行升序为例)
 *    将堆顶与末尾元素进行交换，在对剩余的元素进行大顶堆，此时得到了次小于堆顶的元素，以此往复，直至完成排序。
 */

function heapSort(array) {
  let length = array.length
  // 如果不是数组或者数组长度小于等于1，直接返回不需要进行排序
  if(!Array.isArray(array) || length <= 1) {return}

  buildMaxHeap(array) // 将传入的数组建立为大堆顶

  // 每次循环，将最大的元素与末尾元素交换，然后剩下的元素重新构建为大堆顶
  for(let i = length -1; i > 0; i--) {
    swap(array, 0, i)
    adjustMaxHeap(array, 0, i) // 将剩下的元素重新构建大堆顶
  }

  return array
}

function adjustMaxHeap(array, index, heapSize) {
  /**
   * iMax用于存储最大值索引
   * iLeft用于存储节点的左子元素
   * iRight用于存储节点的右子元素
   */
   let iMax, iLeft, iRight
   while(true) {
     iMax = index // 先假设传入的节点为最大值
     iLeft = 2 * index + 1
     iRight = 2 * index + 2

     // 如果左元素存在，且左子元素大于最大值，则更新最大值索引
     if(iLeft < heapSize && array[iMax] < array[iLeft]) {
       iMax = iLeft
     }

     // 如果右元素存在，且右子元素大于最大值，则更新最大值索引
     if(iRight < heapSize && array[iMax] < array[iRight]) {
       iMax = iRight
     }

     // 如果最大元素被更新了，则交换位置，使父节点大于它的子节点，同时将索引值跟更新为被替换的值，继续检查它的子树
     if(iMax !== index) {
       swap(array, index, iMax)
       index = iMax
     } else {
       break
     }
   }
 }

// function adjustMaxHeap(array, index, heapSize) {
//   let iMax = index,
//   iLeft = 2 * index + 1,
//   iRight = 2 * index + 2,
//   heapSize = heapSize
  
//   // 如果左元素存在，且左子元素大于最大值，则更新最大值索引
//   if(iLeft < heapSize && array[iMax] < array[iLeft]) {
//     iMax = iLeft
//   }

//   // 如果右元素存在，且右子元素大于最大值，则更新最大值索引
//   if(iRight < heapSize && array[iMax] < array[iRight]) {
//     iMax = iRight
//   }

//   if(iMax !== index) {
//     swap(array, index, iMax)
//     index = iMax
//     adjustMaxHeap(array, index, heapSize)
//   }
   
// }

// 构建大顶堆
function buildMaxHeap(array) {
  let length = array.length,
  iParent = parseInt(length >> 1) - 1

  for(let i = iParent; i >= 0; i--) {
    adjustMaxHeap(array, i, length)
  }
}

function swap(array, i, j) {
  let temp = array[i]
  array[i] = array[j]
  array[j] = temp 
}


l=[7, 3, 5, 1, 4, 2, 6]

console.log(heapSort(l))