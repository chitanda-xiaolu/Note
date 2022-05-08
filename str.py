string = "a1 b1 c1" 
#转换成ascii码
ascii_l = []
for s in string:
  ascii_l.append(ord(s))


result = []
different_val = [0, 32]
for index,val in enumerate(ascii_l):
  for i in different_val:
    if 97 <= val <= 122:
      l = [x for x in ascii_l]
      l[index] = val - i
      result.append(l)

print(result)

for i in result:
  print(i)