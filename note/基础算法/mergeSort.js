/**
 * 归并排序是利用归并的思想实现的排序方法，该算法采用经典的分治策略。归并的将数组两两分开直到只包含一个元素，然后
 * 将数组排序合并，最终合并为排序好的数组。
 */

function mergeSort(array) {
    let length = array.length
    if(length === 1) {
        return array
    }

    let mid = parseInt(length >> 1),
    left = array.slice(0, mid)
    right = array.slice(mid, length)
}

function merge(leftArray, rightArray) {
    let result = []
    leftLength = leftArray.length
    rightLength = rightArray.length
    il = 0
    ir = 0

    // 左右两个数组的元素依次，将较小的元素加入结果数组中，直到其中一个数的元素全部加入完则停止
    while(il < leftLength && ir < rightLength) {
        if(leftArray[il] < rightLength[ir]) {
            result.push(leftArray[il++])
        } else {
            result.push(rightArray[ir++])
        }

        // 如果是左边数组还剩余，则把剩余的元素全部加入到结果数组中
        while(il < leftLength) {
            result.push(leftArray[il++])
        }

        // 如果有变数组还剩余，则把剩余的元素全部加入到结果数组中
        while(ir < rightLength) {
            result.push(rightArray[ir++])
        }

        return result
    }
}
