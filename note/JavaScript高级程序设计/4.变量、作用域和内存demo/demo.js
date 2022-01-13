/**
 * demo1
 */
// let color = "blue"
// function changeColor() {
//     if (color === "blue") {
//         color = "red"
//     } else {
//         color = "blue"
//     }
// }
// changeColor()
// console.log("Color is now " + color)

/**
 * demo2
 */

// let color = "blue"
// function changeColor() {
//     let anotherColor = "red"
//     function swapColors() {
//         let tempColor = anotherColor
//         anotherColor = color
//         color = tempColor
//         //这里可以访问color、anotherColor和tempColor
//     }
//     //这里可以访问color和anotherColor、但不能访问tempColor
//     swapColors()
// }

//这里只能访问color

/**
 * 以上代码共涉及3个执行环境：全局环境、changecolor()的局部环境和swapColors()的局部环境。
 * 通过这个例子可以看出内部环境可以通过作用域链访问所有外部环境，但外部环境不能访问内部环境
 * 中的任何变量和函数。所以swapColors()可以自内向外访问changecolor()环境里和全局环境里的
 * 变量。而全局环境不能访问自外访问changecolor()和swapColors()环境中的变量。
 */

let num = [1, 2, 3]
if (num instanceof Array) {
    console.log("num is array")
}