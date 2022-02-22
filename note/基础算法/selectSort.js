// function selectSort(array) {
//   let length = array.length

//   if(!Array.isArray(array) || length <= 1) {return}
//   for(let i = 0; i < length - 1; i++) {
//     let minIndex = i
//     for(let j = i + 1; j < length; j++) {
//       if(array[minIndex] > array[j]) {
//         minIndex = j
//       }
//     }
//     [array[i], array[minIndex]] = [array[minIndex], array[i]]
//   }

//   return array
// }

// l = [7, 1, 6, 4, 2, 5, 3]
// console.log(selectSort(l))