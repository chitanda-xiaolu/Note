### python函数的参数
python函数的参数可以分为默认参数、位置参数、关键字参数、可变参数。
+ 形参：定义函数时的参数，如定义函数def func(a, b) a,b就是形参
+ 实参：调用函数时的参数的值，如调用函数func(2, 3)参数2，3就是实参
+ 默认参数：定义函数时，为形参提供默认值，默认参数必须在最右端。调用函数的时候如果没有传入实参，则取默认参数。如果传入实参则取实参。
  ```py
    def sum(a,b=2):
      return a + b
    sum(1) # 3
    sum(1,3) # 4
  ```
+ 位置参数：调用函数传入实际参数的数量和位置都必须和函数定义时保持一致。
+ 关键字参数：调用函数的时候使用的是键值对的方式，key=values。混合传参时关键字参数必须在位置参数之前。
+ 可变参数
