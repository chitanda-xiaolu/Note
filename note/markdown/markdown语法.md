#### 流程图语法

+ 声明格式

  ```perl
  ​```mermaid
      graph LR 
      ...
  ​```
  ```

+ 使用**graph**声明流程图的方向(TB从上到下，LR从左到右)

+ 声明图标

  | 图形       | 符号                       |
  | ---------- | -------------------------- |
  | 矩形       | name[label]                |
  | 内凹五边形 | name>label]                |
  | 圆角矩形   | name(label)                |
  | 圆形       | name((label))              |
  | 菱形       | name{label}                |
  | 六边形     | name{{label}}              |
  | 梯形       | name[\label/],name[/label] |
  | 平行四边形 | name[\label],name[/label/] |

  source(dataGenerator)
  mysql[mysqlDB]
  kafka[kafka]
  phoenix((phoenix))
  flinkDataSync[flinkDataSync]
  dataServer>dataServer]

+ 描述逻辑

  source --> mysql --> kafka --> flinkDataSync --> phoenix ==> dataServer

  ```mermaid
  graph LR
  source(dataGenerator)
  mysql[mysqlDB]
  kafka[kafka]
  phoenix((phoenix))
  flinkDataSync[flinkDataSync]
  dataServer>dataServer]
  source --> mysql --> kafka --> flinkDataSync --> phoenix ==> dataServer
  ```





+ e.g

  ```mermaid
      graph LR
      source(dataGenerator)
      mysql[mysqlDB]
      kafka[kafka]
      phoenix((phoenix))
      flinkDataSync[flinkDataSync]
      dataServer>dataServer]
  
      source --> mysql --flinkCDC.-> kafka --> flinkDataSync --> phoenix ==> dataServer
      flinkDataSync ==> clikhouse((clikhouse)) --> dataServer
      kafka --> flinkAnalyse[flinkAnalyse] --> kafka
  
  ```

  