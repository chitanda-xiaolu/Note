function insetSort(array) {
    let length = array.length
    if(!Array.isArray(array) || length <= 1) {return}

    for(let i=1; i<length; i++) {
        let temp = array[i]
        let j = i

        while(j - 1 && array[j] < array[j - 1]) {
            array[j] = array[j -1]
            j--
        }

        array[j] = temp
    }
}