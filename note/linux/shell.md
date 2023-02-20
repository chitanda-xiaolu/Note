[TOC]



#### 管道符

使用管道操作符“|”可以把一个命令的标准输出传送到另一个命令的标准输出然中

#### 特殊状态变量

shell脚本和函数穿参时变量之间需要用空格分隔开

```bash
$? 上次命令执行状态返回值，0为执行正确，非0为执行失败
$$ 当前shell脚本的进程号
$! 上一次后台进程的PID
$_ 获取上条命令的最后一个参数

$0 获取shell脚本文件名，以及脚本路径
$n 获取shell脚本的第n个参数，n在1-9之间，当n大于9时需要用${}获取变量如${10}
$# 传入脚本的参数个数
$* 获取传入脚本的所有参数，所有参数被视为一个整体,当引用$*使用引号时因为所有参数被视为一个整体对其进行便利时只会进行一次遍历
$@ 获取传入脚本的所有参数，当引用$*使用引号时因为所有参数被分别传入

	小陆@MSI MINGW64 ~/Desktop
    $ cat test.sh
    #!/bin/bash
    echo '$*'
    for n in "$*";do
      echo $n
    done
    echo '$#'
    for m in "$@";do
      echo $m
    done

    小陆@MSI MINGW64 ~/Desktop
    $ bash test.sh 1 2 3
    $*
    1 2 3
    $#
    1
    2
    3


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
    小陆@MSI MINGW64 ~/Desktop
    $ printf "你好\t我是\tchitanda"
    你好    我是    chitanda

```

+ eval 执行多条命令

```bash
    小陆@MSI MINGW64 ~/Desktop/note/note (master)
    $ eval ls; cd linux/
    JavaScript高级程序设计/  test.js    基础算法/  计算机网络/
    linux/                   前端面试/  学习笔记/

    小陆@MSI MINGW64 ~/Desktop/note/note/linux (master)
    $

```

+ exec 不创建子进程，执行后续命令，且执行完毕后，自动exit

```bash


```

#### shell子串的用法

+ **${变量}**  返回变量的值

```- bash
    小陆@MSI MINGW64 ~/Desktop
    $ name="chitanda"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name}
    chitanda
```

- **${#变量}**  返回变量的字符长度，这是统计变量字符长度最高效的方法

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ name="chitanda"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${#name}
    8
    
    # 也可以使用echo $name | wc -L来统计字符长度，wc -L可以统计最长那一行字符串的字符长度
    小陆@MSI MINGW64 ~/Desktop
    $ echo $name | wc -L
    8
    
    #使用expr统计字符长度，用法：expr length "${name}"或expr length "$name"
	小陆@MSI MINGW64 ~/Desktop
    $ expr length "${name}"
    8

    小陆@MSI MINGW64 ~/Desktop
    $ expr length "$name"
    8
    
    #使用awk统计变量字符串长度
    小陆@MSI MINGW64 ~/Desktop
    $ echo $name | awk '{print length($0)}'
    8



```

- **${变量:index}**  返回从index开始之后的字符串(起始索引为0)

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ name="chitanda"
    
    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name:3}
    tanda
```

- **${变量:index:count}**  截取变量中从index开始的count个字符

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ name="chitanda"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name:3:2}
    ta
```

- **${变量#expression}**  从变量的左边开始进行最短匹配，满足expression条件的字符将被删除

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ str="abcABC123ABCabc"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${str#a*c}  #从左开始匹配变量中满足a*c的最短字符，然后将其删除
    ABC123ABCabc   #abc满足表达式被删除

```

- **${变量##delete_string}**  从变量的左边开始进行最长匹配，满足expression条件的字符将被删除

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ str="abcABC123ABCabc"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${str##a*c} #从左开始匹配变量中满足a*c的最长字符，然后将其删除
    				   #表达式匹配了整个字符串，所以输出结果为空
```

- **${变量%delete_string}**   从变量的右边开始进行最短匹配，满足expression条件的字符将被删除

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ str="abcABC123ABCabc"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${str%a*c}
    abcABC123ABC

```

- **${变量%%delete_string}**  从变量的左边开始进行最长匹配，满足expression条件的字符将被删除

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ str="abcABC123ABCabc"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${str%%a*c}
	
```

- **${变量/string/parttern}**  将变量中的第一个string替换为parttern

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ str="Hi,man,i am your brother."

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${str/man/guys}
    Hi,guys,i am your brother.

```

- **${变量/string/parttern}**  将变量中的所有string替换成parttern

```bash
    小陆@MSI MINGW64 ~/Desktop
    $ str2="aaBBCCaa"

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${str2//aa/AA}
    AABBCCAA

```

+ 批量删除文件名

```bash
	# 新建测试示例文件
    小陆@MSI MINGW64 ~/Desktop/test
    $ touch bilibili_{1..5}_finished.jpg

    小陆@MSI MINGW64 ~/Desktop/test
    $ ls
    bilibili_1_finished.jpg  bilibili_3_finished.jpg  bilibili_5_finished.jpg
    bilibili_2_finished.jpg  bilibili_4_finished.jpg
    
    小陆@MSI MINGW64 ~/Desktop/test
    $ touch bilibili_{1..5}_finished.png

    小陆@MSI MINGW64 ~/Desktop/test
    $ ll
    total 0
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_1_finished.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_1_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_2_finished.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_2_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_3_finished.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_3_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_4_finished.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_4_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_5_finished.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_5_finished.png
	
	# 批量修改文件名，将所有Jpg文件文件名中的finished去掉
	小陆@MSI MINGW64 ~/Desktop/test
    $ for p in `ls *finished*.jpg`;do mv $p `echo ${p//_finished/}`;done

    小陆@MSI MINGW64 ~/Desktop/test
    $ ll
    total 0
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_1.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_1_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_2.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_2_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_3.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_3_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_4.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_4_finished.png
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:10 bilibili_5.jpg
    -rw-r--r-- 1 小陆 197121 0 Feb 16 17:45 bilibili_5_finished.png
```

#### shell拓展变量

```bash
    # ${parameter:-word} 如果parameter变量值为空，返回word字符串;否则直接返回变量
    小陆@MSI MINGW64 ~/Desktop
    $ echo $gretting

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${gretting:-hello}
    hello
	
	小陆@MSI MINGW64 ~/Desktop
    $ echo $name
    chitanda

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name:-hello}
    chitanda


    # ${parameter:=word} 如果parameter变量为空，则word替换变量值，并将值返回；否则直接返回变量
    小陆@MSI MINGW64 ~/Desktop
    $ echo $gretting

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${gretting:=hello}
    hello

	小陆@MSI MINGW64 ~/Desktop
    $ echo $name
    chitanda

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name:=hello}
    chitanda

    # ${parameter:?word} 当变量为空时主动抛出错误信息
    小陆@MSI MINGW64 ~/Desktop
    $ echo $gretting


    小陆@MSI MINGW64 ~/Desktop
    $ echo ${gretting:?}
    bash: gretting: parameter null or not set

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${gretting:?value is not defined}
    bash: gretting: value is not defined
	
	小陆@MSI MINGW64 ~/Desktop
    $ echo $name
    chitanda

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name:?value is not defined}
    chitanda


    # ${parameter:+word} 如果变量parameter变量为空，什么都不做，否则word返回
    小陆@MSI MINGW64 ~/Desktop
    $ echo $greeting


    小陆@MSI MINGW64 ~/Desktop
    $ echo ${gretting:+hello}


    小陆@MSI MINGW64 ~/Desktop
    $ echo $name
    chitanda

    小陆@MSI MINGW64 ~/Desktop
    $ echo ${name:+
```

**实际应用**

数据备份，删除过期数据的脚本

```bash
    # 删除7天以上的过期数据
    find 需要搜索的目录 -name 你要搜索的文件名字  -type 文件类型  -mtime +7 | xargs rm -f
```

#### 父子shell

​	[父shell和子shell_云疏不知数的博客-CSDN博客_父shell和子shell](https://blog.csdn.net/qq_43808700/article/details/115832946)

+ source和点，执行脚本，只在当前的shell环境中执行生效，不生成子shell

```mermaid
graph LR
source(source script.sh)
command1(command1)
command2(command2)
source --> command1 --> command2
```

+ 指定bash sh解释器运行脚本时，会开启子shell运行脚本命令

  ```mermaid
  graph LR
  source(/bin/bash script.sh or sh script.sh)
  bashshell(bash shell)
  command1(command1)
  command2(command2)
  source --> bashshell
  source --subshell.-> command1 --> command2
  
  ```

+ ./script，都会指定shebang，通过解释器运行，即会开启子shell执行脚本

  ```mermaid
  graph LR
  source(./script.sh)
  bashshell(bash shell)
  command1(command1)
  command2(command2)
  source --> bashshell
  source --subshell.-> command1 --> command2
  ```



+  创建进程列表(创建子shell)

  ```perl
  可以使用()开启进程列表即开启子shell, 可以通过echo $BASH_SUBSHELL查看当前shell环境，BASH_SUBSHELL值为非零是处于子shell,通常会用子shell进行多线程处理，提高程序并发执行效率。
  ```

  ```bash
  (pwd;(pwd;(echo $BASH_SUBSHELL)))
  ```



#### 内置命令/外置命令

> 内置命令：在系统启动时就加载如内存，常驻内存，执行效率更高，但是占用资源
>
> 外置命令：用户需要从硬盘中读取程序文件，再读入内存加载，外置命令通常存放在一下目录：/bin  /usr/bin /sbin  /usr/sbin

> 可用"type 命令"查看命令类型

```bash
小陆@MSI MINGW64 ~/Desktop
$ type cd
cd is a shell builtin

```

> 内置命令不会开启子shell去执行命令
>
> 外置命令会开启子shell



#### SHELL算术运算

+ shell常见算术运算符

  | 算术运算符            | 意义                                               |
  | --------------------- | -------------------------------------------------- |
  | +  -                  | 加法（或正号）减法（或负号）                       |
  | *  /  %               | 乘法  除法  取余                                   |
  | **                    | 幂运算                                             |
  | ++  --                | 自加  自减                                         |
  | &&  \|\| ！           | 逻辑与 (and)  或(or)  非(取反)                     |
  | < <=  >  >=           | 比较符(小于  小于等于  大于  大于等于)             |
  | ==  !=  =             | 比较符(相等  不相等 对于字符串"="也可以表示相当于) |
  | <<  >>                | 向左位移  向右位移                                 |
  | ~  \|  &  ^           | 按位取反  按位异或  按位与  按位或                 |
  | =  +=  -=  *=  /=  %= | 赋值运算                                           |

+ shell常见算术命令

  | 运算操作符与运算命令 | 意义                                                 |
  | -------------------- | ---------------------------------------------------- |
  | (())                 | 用于整数运算的常用运算符，效率很高                   |
  | let                  | 用于整数运算，类似"(())"                             |
  | expr                 | 可用于整数运算，但是还有很多其他的额外功能           |
  | bc                   | Linux下的一个计算程序(适合整数及小数运算)            |
  | $[]                  | 用于整数运算                                         |
  | awk                  | awk既可以用于整数运算，也可以用于小数运算            |
  | declare              | 定义变量值和属性，-i参数可以用于定义整形变量，做运算 |

+ 双小括号"(())"的操作方法

  | 运算操作符与运算命令 | 意义                                                      |
  | -------------------- | --------------------------------------------------------- |
  | ((i=i+1))            | 这种写法算术运算后赋值，即将i+1的运算结果赋值给变量i      |
  | i=$((i+1))           | 可以在"(())"前加$符，表示将表达式运算后赋值给i            |
  | ((8>7&&5==))         | (())还以用于逻辑运算                                      |
  | echo $((2+1))        | 需要直接输出或获取运算表达式的运算结果时，需要在(())前加$ |

  ```bash
      小陆@MSI MINGW64 ~/Desktop
      $ echo ((i+=1))
      bash: syntax error near unexpected token `('
  
      小陆@MSI MINGW64 ~/Desktop
      $ echo $((i+=1))
      2
  ```

+ expr

  ```bash
      # 使用expr时运算数值与运算符之间必须要有空格，否则无法返回正确的计算结果
      小陆@MSI MINGW64 ~/Desktop
      $ expr 3 + 1
      4
      小陆@MSI MINGW64 ~/Desktop
      $ expr 3+1
      3+1
  
      # 当运算为shell里的元字符(如"+"  "*"等)时，expr无法得到正确的运算结果，需要使用到转义字符
  	小陆@MSI MINGW64 ~/Desktop
      $ expr 3 * 5
      expr: syntax error: unexpected argument
      
      小陆@MSI MINGW64 ~/Desktop
      $ expr 3 \* 5
      15
      
      # expr进行字符的长度统计
  	小陆@MSI MINGW64 ~/Desktop
      $ expr length 1234567
      7
  
  	# expr进行逻辑运算
  	小陆@MSI MINGW64 ~/Desktop
      $ expr 5 \> 6
      0
  	小陆@MSI MINGW64 ~/Desktop
      $ expr 8 \> 6
      1
  
  ```

  **expr模式匹配**

  > expr  要进行匹配的字符串   ： 匹配模式  ,会根据匹配模式进行字符匹配，返回匹配字符的字符长度

  ```bash
      小陆@MSI MINGW64 ~/Desktop
      $ p=123.jpg
  
      小陆@MSI MINGW64 ~/Desktop
      $ expr p : .*\.jpg
      0
  
      小陆@MSI MINGW64 ~/Desktop
      $ expr $p : .*\.jpg
      7
  
  ```

+ bc

  bc结合管道符进行数值运算

  ```bahs
  	echo "33.3*2" | bc #66.6
  	
  	# 计算0-100的求和结果
  	echo {1..100} | tr " " "+" | bc
  	echo seq -s "+" 100 | bc
  ```

+ 使用awk进行数值运算

  ```bash
  	小陆@MSI MINGW64 ~/Desktop
      $ echo "3.2 2.2" | awk '{print $1+$2}'
      5.4
  
  ```

#### shell条件测试语法

条件测试语法中使用变量时要给变量加上""

| 条件测试语法     | 说明                                                         |
| ---------------- | ------------------------------------------------------------ |
| test<测试表达式> | 这是利用test命令进行条件测试表达式的方法。test命令和"<测试表达式>"之间至少有一个空格 |
| [<测试表达式>]   | 和test命令用法相同，[]的边界之间至少有一个空格               |
| [[<测试表达式>]] | [[]]的边界之间至少有一个空格                                 |
| ((<测试表达式>)) | 一般用于if语句里。两端不需要空格                             |

+ test参数语法

  ```perl
  1. test -e filename
  
  -e 判断filename是否存在
  -f 判断filename是否为普通文件
  -d 判断filename是否为目录
  -b 判断filename是否为block device装置
  -c 判断filename是否为character device装置
  -S 判断filename是否为Socket文件
  -p 判断filename是否为FIFO(pipe)文件
  -L 判断filename是否为一个连结档
  
  -r 判断filename是否具有可读属性
  -w 判断filename是否具有可写属性
  -x 判断filename是否具有可执行属性
  -u 判断filename是否具有SUID属性
  -g 判断filename是否具有SGID属性
  -k 判断filename是否具有Sticky bit属性
  -s 判断filename是否为空白文件
  
  
  2. 文件之间进行比较：test file1 操作符 file2，有如下操作符
  -nt(new then) 判断file1是否比file2新
  -ot(old then) 判断file1是否比file2旧
  -ef 判断file1与file2是否为同一个文件，可用判断hard link的判断定上。主要意义在判定两个文件石头指向同一个inode
  
  3. 两个整数之间的比较
  -eq 两数值是否相等
  -ne 不等于
  -gt 大于
  -lt 小于
  -ge 大于等于
  -le 小于等于
  
  
  4. 判断字符串数据
  test -z string 若字符串为空字符串，返回true
  test -n string 若字符串为空字符串，返回false
  
  ```

+  []条件测试

  > 在[]条件判断中使用变量时，变量要加上""

  ```bash
  小陆@MSI MINGW64 ~/Desktop
  $ ls
  preview.jpg
  
  小陆@MSI MINGW64 ~/Desktop
  $ p=preview.jpg
  
  小陆@MSI MINGW64 ~/Desktop
  $ [ -f "$p" ] && echo "jpg is exist" || echo "jgp not exist"
  jpg is exist
  
  ```

  > 在使用数值比较符(< > = >= <=)时需要添加转义符,!=不需要加转义符

  ```bash
  小陆@MSI MINGW64 ~/Desktop
  $ [ 1 > 2 ] && echo yes || echo no
  yes
  
  小陆@MSI MINGW64 ~/Desktop
  $ [ 1 \> 2 ] && echo yes || echo no
  no
  
  小陆@MSI MINGW64 ~/Desktop
  $ [ 1 != 2 ] && echo yes || echo no
  yes
  
  ```

+ [[]]条件测试

  > 在[[]]中数值比较符(< > = >= <=)不需要加转义符

#### 逻辑运算符

&&  -a 同为逻辑与；||与-o同为逻辑或

| 在[]和test中使用的操作符 | 在[[]]和(())中使用的操作符 | 说明                                   |
| ------------------------ | -------------------------- | -------------------------------------- |
| -a                       | &&                         | 符号两端结果都为真时返回结果为真       |
| -o                       | \|\|                       | 符号两端结果其中一个为真时返回结果为真 |
| !                        | !                          | 取反                                   |



#### shell函数

函数定义的语法

```bash
## 语法
# 完整的定义方式
function 函数名() {
	# 函数体
}

#e.g
function gretting() {
	echo "Hello,world"
}

gretting #调用函数

# 使用function关键字时也可以省略()
function gretting {
	echo "Hello,worl"
}

#  也可以不使用关键字定义函数，可以直接使用函数名加函数体的形式定义函数，但不能省略函数名后的括号
gretting() {
	echo "Hello,world"
}

```

+ 函数必须先定义，再执行，shell脚本时自上而下执行的
+ 函数体内定义的变量，称之为局部变量，只能在函数体内使用，无法在函数体外使用
+ 函数体内可添加return语句，作用是退出函数，且赋予返回值给调用该函数的程序，也就是shell脚本
+ return语句和exit不同
  - return是结束函数的执行，返回一个(退出值，返回值)
  - exit是结束shell环境，返回一个(退出值，返回值)给当前的shell
+ 函数如果单独写在一个文件里，需要用source读取
+ 函数内，使用local关键字定义局部变量

