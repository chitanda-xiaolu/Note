import pandas as pd

df_excel = pd.read_excel("repo_base_info.xlsx")
print(df_excel)

df_excel.to_csv("repo_base_info.csv", encoding="gb18030")