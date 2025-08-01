# NCBI SNP Spider
### NCBI SNP Spider是专门用于爬取NCBI中SNP信息的程序，非常简单易用。
### 只要提供基因名和物种名，便可获取所有与该基因相关的SNPs。
![](https://raw.githubusercontent.com/ScottSmith666/NCBI-SNP-Spider/refs/heads/main/imgs/ncbi.png)

## 1. 安装本程序用到的依赖
本项目依赖Python3.10软件，请自行提前安装好。

本项目所需依赖列于根目录的“requirements.txt”中，参考 https://github.com/ScottSmith666/HMDB-Spider 中的依赖安装方法。

## 2. ChromeDriver
本项目依赖ChromeDriver，Windows x64, macOS arm64和Linux x64版本已内置于项目目录中，一般情况下无需额外下载。

如果您使用的是macOS x64版本，请自行于 https://googlechromelabs.github.io/chrome-for-testing/ 下载并替换。

## 3. 用法
本程序为命令行软件，需要结合终端使用，以基因名“NFATC1”和物种名“Homo_sapiens”为例（注意⚠️：物种名内的空格必须由下划线代替，如：Homo_sapiens）：

第一个参数需传入物种名，第二个参数需传入基因名。

在Windows系统，命令为：
```powershell
python nss Homo_sapiens NFATC1
```
在macOS和Linux中，命令为：
```shell
./nss Homo_sapiens NFATC1
```
或者
```shell
python3 nss Homo_sapiens NFATC1
```
本程序具有断点续爬功能，即程序在爬取过程中意外终止，下次运行相同的命令时本程序将跳过先前已爬取的内容，从上次终止的位置继续爬取。

## 4. 爬取结果

| rs_id | var_type | alleles | chr_grch38 | position_in_chr_grch38 | chr_grch37 | position_in_chr_grch37 | merged | merged_into_rs_id | in_which_gene | from_species |
|-------|----------|-------|------------| ---|------------| --- |--------|-------------------|---------------| --- |
| rs149308374  | SNV      | C>A,T | 18         | 79410978 | 18         | 77170978 | No     | None              | NFATC1        | Homo sapiens |
| rs149271669  | SNV      | C>G,T | 18         | 79527561 | 18         | 77287561 | No     | None              | NFATC1           | Homo sapiens |
| rs149224832  | SNV      | A>G   | 18         | 79498959 | 18         | 77258959 | No     | None              | NFATC1           | Homo sapiens |
| ...   | ...      | ...   | ...        | ... | ...        | ... | ...    | ...               | ...           | ... |
| rs1445697066   | DELINS   | 过长... | 18         | 79464614 | 18         | 77224614 | Yes    | rs57175022        | NFATC1           | Homo sapiens |
| ...   | ...      | ...   | ...        | ... | ...        | ... | ...    | ...               | ...           | ... |

字段名解释：
1. `rs_id`: SNP ID
2. `var_type`: 突变形式
3. `alleles`: 等位基因
4. `chr_grch38`: 染色体编号（GRCh38版本）
5. `position_in_chr_grch38`: SNP在染色体内的位置（GRCh38版本）
6. `chr_grch37`: 染色体编号（GRCh37版本）
7. `position_in_chr_grch37`: SNP在染色体内的位置（GRCh37版本）
8. `merged`: 该SNP是否被合并
9. `merged_into_rs_id`: 该SNP被合并到哪个新SNP中
10. `in_which_gene`: 该SNP在哪个基因上
11. `from_species`: 物种名

### 如果本程序有解决了一些你生活中的小烦恼，不妨请Scott Smith喝杯咖啡吧[Doge]
