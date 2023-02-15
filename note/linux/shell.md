####特殊状态变量
```bash
$? 上次命令执行状态返回值，0为执行正确，非0为执行失败
$$ 当前shell脚本的进程号
$! 上一次后台进程的PID
$_ 获取上条命令的最后一个参数

#可通过man bash查询特殊状态变量的说明
```

#### bash一些基础的内置命令
+ echo 默认以换行符结尾
参数：
   - -n 不换行输出
   - -e 解析字符串中的特殊符号
   \n换行
   \r回车
   \t制表符

```bash
   小陆@MSI MINGW64 ~/Desktop
    $ echo "hello,";echo "chitanda"
    hello,
    chitanda

    小陆@MSI MINGW64 ~/Desktop
    $ echo -n "hello,";echo "chitanda"
    hello,chitanda

```

+ printf 用于打印输出类似于Python的print,默认无换行符结尾
```bash

```
