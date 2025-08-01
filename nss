#!/Volumes/Execute/Apps/conda_packages/mad-professor/bin/python

import os
import re
import sys
import time
import pandas as pd
from tqdm import tqdm
import requests as req
from pathlib import Path
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.action_chains import ActionChains


DEBUG = False
BASE_PATH = os.path.abspath('.')
QUERY_GENE_URL = "https://www.ncbi.nlm.nih.gov/gene"
QUERY_SNPS_URL = "https://www.ncbi.nlm.nih.gov/snp"
NUM_PER_PAGE = 200
HEADERS = {
    "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
    "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
}
# PROXIES = {
#     "https": "127.0.0.1:1087",
#     "http": "127.0.0.1:1087",
# }

class GetSNPs:
    """This class is aimed to get SNP(s) in gene"""
    def __init__(self, species, gene_name):
        # Parameters
        self.species = species
        self.gene_name = gene_name

        # Set request session.
        self.session = req.Session()
        self.retry = Retry(connect=3, backoff_factor=0.5)
        self.adapter = HTTPAdapter(max_retries=self.retry)
        self.session.mount('http://', self.adapter)
        self.session.mount('https://', self.adapter)

        # Get OS kind
        os_kind = sys.platform

        # Get NCBI cookies
        print("Obtaining NCBI cookies...")
        main_req = self.session.get(QUERY_GENE_URL + ("?term=%s" % self.gene_name), headers=HEADERS)
        self.ncbi_cookies = req.utils.dict_from_cookiejar(main_req.cookies)
        print("Get cookies: %s" % self.ncbi_cookies)
        print("Obtain NCBI cookies complete!")

        # Init Selenium
        print("Init Selenium...")
        self.options = Options()
        if not DEBUG:
            self.options.add_argument("--headless")
        self.options.add_argument("--no-sandbox")
        self.options.add_argument("--start-maximized")
        self.options.add_argument("--disable-dev-shm-usage")
        self.options.add_experimental_option("excludeSwitches", ["enable-automation"])
        self.options.add_experimental_option('useAutomationExtension', False)
        print("Loading driver '%s'..." % (BASE_PATH + os.sep + "chromedriver-" + os_kind + os.sep + "chromedriver%s" % (".exe" if os_kind == "win32" else "")))
        self.service = Service(executable_path=BASE_PATH + os.sep + "chromedriver-" + os_kind + os.sep + "chromedriver%s" % (".exe" if os_kind == "win32" else ""))
        print("Init Selenium complete!")

    def gen_req_ncbi_gene_body(self, current_page):
        return {
            "term": self.gene_name + ' ',
            "EntrezSystem2.PEntrez.Gene.Gene_PageController.PreviousPageName": "results",
            "EntrezSystem2.PEntrez.Gene.Gene_Facets.FacetsUrlFrag": "filters=current-only",
            "EntrezSystem2.PEntrez.Gene.Gene_Facets.FacetSubmitted": "false",
            "EntrezSystem2.PEntrez.Gene.Gene_Facets.BMFacets": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.sPresentation": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.sPageSize": "%d" % NUM_PER_PAGE,  # Number per page
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.sSort": "none",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.FFormat": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.FSort": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.FileFormat": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.LastPresentation": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.Presentation": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.PageSize": "%d" % NUM_PER_PAGE,
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.LastPageSize": "%d" % NUM_PER_PAGE,
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.Sort": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.LastSort": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.FileSort": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.Format": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.LastFormat": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.PrevPageSize": "%d" % NUM_PER_PAGE,
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.PrevPresentation": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.PrevSort": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_ResultsController.RunLastQuery": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Entrez_Pager.CurrPage": "%d" % current_page,
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.sPresentation2": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.sPageSize2": "%d" % NUM_PER_PAGE,
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.sSort2": "none",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.FFormat2": "tabular",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Gene_DisplayBar.FSort2": "",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Taxport.TxView": "list",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Taxport.TxListSize": "5",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Entrez_MultiItemSupl.RelatedDataLinks.rdDatabase": "rddbto",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Entrez_MultiItemSupl.RelatedDataLinks.DbName": "gene",
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Discovery_SearchDetails.SearchDetailsTerm": "%s[All Fields] AND alive[prop] OR replaced[Properties] OR discontinued[Properties]" % self.gene_name,
            "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.HistoryDisplay.Cmd": "PageChanged",
            "EntrezSystem2.PEntrez.DbConnector.Db": "gene",
            "EntrezSystem2.PEntrez.DbConnector.LastDb": "gene",
            "EntrezSystem2.PEntrez.DbConnector.Term": self.gene_name,
            "EntrezSystem2.PEntrez.DbConnector.LastTabCmd": "",
            "EntrezSystem2.PEntrez.DbConnector.LastQueryKey": "1",
            "EntrezSystem2.PEntrez.DbConnector.IdsFromResult": "",
            "EntrezSystem2.PEntrez.DbConnector.LastIdsFromResult": "",
            "EntrezSystem2.PEntrez.DbConnector.LinkName": "",
            "EntrezSystem2.PEntrez.DbConnector.LinkReadableName": "",
            "EntrezSystem2.PEntrez.DbConnector.LinkSrcDb": "",
            "EntrezSystem2.PEntrez.DbConnector.Cmd": "PageChanged",
            "EntrezSystem2.PEntrez.DbConnector.TabCmd": "",
            "EntrezSystem2.PEntrez.DbConnector.QueryKey": "",
        }

    def get_ncbi_gene_id(self):
        """This method is aimed to get NCBI GENE ID."""
        print("Start getting NCBI GENE ID (gene name is \"%s\")..." % self.gene_name)
        curr_page = 1
        gene_id = -1  # If gene_id still equals -1, it's because the species is not found.
        while True:
            is_find_in_page = False
            hm = self.session.post(QUERY_GENE_URL, headers=HEADERS, data=self.gen_req_ncbi_gene_body(curr_page),
                                   cookies=self.ncbi_cookies).text
            soup = BeautifulSoup(hm, 'html.parser')
            last_page_tag = soup.find_all("input", attrs={
                "name": "EntrezSystem2.PEntrez.Gene.Gene_ResultsPanel.Entrez_Pager.cPage"
            })  # get total num of pages element
            if int(soup.find_all("meta", attrs={"name": "ncbi_resultcount"})[0]['content']) == 0:  # Cannot find gene name
                return -2
            if len(last_page_tag) == 0:  # Only one page
                total_page = 1
            else:
                total_page = int(last_page_tag[0]['last'])
            print("Query in page: %d/%d..." % (curr_page, total_page))
            page_table_tag = soup.find_all("tr", attrs={"class": "rprt"})  # get all results for gene
            n = 1
            for i in page_table_tag:
                table_display_gene_name_list = i.find_all("span", attrs={"class": "highlight"})
                if len(table_display_gene_name_list) == 0:
                    continue
                table_display_gene_name = table_display_gene_name_list[0].text
                match_reg = re.compile(r"(\[)(.+)( )(\()(.+)(\))(\])")  # Match the species
                match_reg_only_latin = re.compile(r"(\[)(.+)(\])")
                query_species = ""
                if len(match_reg.findall(i.text)) == 0:
                    query_species = match_reg_only_latin.findall(i.text)[0][1]
                else:
                    query_species = match_reg.findall(i.text)[0][1]
                if query_species == self.species and self.gene_name == table_display_gene_name.upper():  # Find right species
                    # Find gene id in right species
                    gene_id = int(i.find_all("span", attrs={"class": "gene-id"})[0].text[4:])
                    print("Successfully get NCBI GENE ID (gene name is \"%s\", id is %d)!" % (self.gene_name, gene_id))
                    is_find_in_page = True
                    break
                n += 1
            if is_find_in_page:
                break
            else:
                curr_page += 1
            if curr_page > total_page:
                break
            time.sleep(1)  # Control the speed
        return gene_id

    def catch_snps_in_each_page(self, driver, current_page, gene, species):
        # New a Pandas DataFrame
        page_df = pd.DataFrame(columns=[
            "rs_id",
            "var_type",
            "alleles",
            "chr_grch38",
            "position_in_chr_grch38",
            "chr_grch37",
            "position_in_chr_grch37",
            "merged",
            "merged_into_rs_id",
            "in_which_gene",
            "from_species",
        ])

        # input and enter to jump the customized page
        time.sleep(1)
        input_page = driver.find_element(By.ID, "pageno")
        input_page.clear()
        input_page.send_keys(current_page)
        input_page.send_keys(Keys.ENTER)
        time.sleep(1)
        present_page_code = driver.page_source  # get source code of page
        soup = BeautifulSoup(present_page_code, 'html.parser')
        page_snps_info_tag_list = soup.find_all("div", attrs={"class": "rprt"})
        for i in page_snps_info_tag_list:
            got_full_snp_name = i.find_all("span")[1].text
            got_snp_var_type = i.find_all("dd")[0].text
            got_snp_alleles = i.find_all("dd")[1].find_all("span")[0].text
            got_snp_in_chr_position = i.find_all("dd")[2].text
            got_snp_in_chr_position_list = re.split(r'\(GRCh3\d\)', got_snp_in_chr_position)
            snp_position_grch38, snp_position_grch37 = "no mapping", "no mapping"
            if len(got_snp_in_chr_position_list) >= 2:
                snp_position_grch38, snp_position_grch37 = got_snp_in_chr_position_list[0].strip(), \
                    got_snp_in_chr_position_list[1].strip()
            else:
                snp_position_grch38 = got_snp_in_chr_position_list[0].strip()

            snp_full_name_list = got_full_snp_name.split("[")[0].strip().split(" ")
            snp_name = snp_full_name_list[0]
            merged_into_snp_name = "None"
            if "merged" in got_full_snp_name:
                merged_into_snp_name = snp_full_name_list[-1].strip()

            line_df = pd.DataFrame({
                "rs_id": snp_name,
                "var_type": got_snp_var_type,
                "alleles": got_snp_alleles,
                "chr_grch38": -1 if snp_position_grch38 == "no mapping" else snp_position_grch38.split(":")[0],
                "position_in_chr_grch38": -1 if snp_position_grch38 == "no mapping" else snp_position_grch38.split(":")[1],
                "chr_grch37": -1 if snp_position_grch37 == "no mapping" else snp_position_grch37.split(":")[0],
                "position_in_chr_grch37": -1 if snp_position_grch37 == "no mapping" else snp_position_grch37.split(":")[1],
                "merged": "Yes" if "merged" in got_full_snp_name else "No",
                "merged_into_rs_id": merged_into_snp_name,
                "in_which_gene": gene,
                "from_species": species,
            }, index=[0])
            page_df = pd.concat([page_df, line_df], ignore_index=True)
        return page_df

    def get_snps(self):
        """This method is aimed to get SNP(s) in gene."""
        gid = self.get_ncbi_gene_id()
        if gid == -2:
            print("Your customized gene name \"%s\" doesn't exist! Program is exiting..." % self.gene_name)
            exit(0)
        elif gid == -1:
            print("Your customized species \"%s\" doesn't exist! Program is exiting..." % self.species)
            exit(0)
        print("Start get all SNPs in gene \"%s\" (id is %d)..." % (self.gene_name, gid))

        # get SNPs data with Selenium
        driver = webdriver.Chrome(options=self.options)
        actions = ActionChains(driver)
        driver.get(QUERY_SNPS_URL + "?LinkName=gene_snp&from_uid=" + str(gid))  # Open the SNPs website.
        time.sleep(1)  # Waiting for 2 seconds.
        num_per_page_menu = driver.find_element(By.ID,
                "EntrezSystem2.PEntrez.Snp.Snp_ResultsPanel.Snp_DisplayBar.Display")  # Point the drop menu of num in page
        actions.click(num_per_page_menu).perform()
        time.sleep(2)
        num_200 = driver.find_element(By.ID, "ps200")  # Point the radiobutton of num in page
        actions.click(num_200).perform()
        time.sleep(2)

        pages_num = int(driver.find_element(By.ID, "pageno").get_attribute('last'))
        print("Get total pages: %d" % pages_num)

        if not Path(BASE_PATH + os.sep + "temp_files").is_dir():
            os.mkdir(BASE_PATH + os.sep + "temp_files")

        for curr_page in range(1, pages_num + 1):
            print("Getting SNPs in page: %d/%d..." % (curr_page, pages_num))
            if Path(BASE_PATH + os.sep + "temp_files" + os.sep + (
                    "%s_%s_SNPs_page_%d.csv" % (self.gene_name, self.species, curr_page))).is_file():
                print("%s_%s_SNPs_page_%d.csv is exists, skipping..." % (self.gene_name, self.species, curr_page))
                continue
            time.sleep(1)
            page_snp_table = self.catch_snps_in_each_page(driver, curr_page, self.gene_name, self.species)
            print("Page: %d/%d complete!" % (curr_page, pages_num))
            page_snp_table.to_csv(BASE_PATH + os.sep + "temp_files" + os.sep + ("%s_%s_SNPs_page_%d.csv" % (self.gene_name, self.species, curr_page)), index=False)

            # Alert to indicate finish
            if DEBUG:
                driver.execute_script("window.alert('Page %d/%d is finished! Switching to next page...');" % (curr_page, pages_num))
                alert_tab = driver.switch_to.alert
                time.sleep(1.5)
                alert_tab.accept()
            print("Page %d/%d is finished! Switching to next page..." % (curr_page, pages_num))

        print("Catch all SNPs in gene \"%s\" complete!" % self.gene_name)

    def merge(self, file_name):
        print("All files got, merging...")
        all_df = pd.DataFrame(columns=[
            "rs_id",
            "var_type",
            "alleles",
            "chr_grch38",
            "position_in_chr_grch38",
            "chr_grch37",
            "position_in_chr_grch37",
            "merged",
            "merged_into_rs_id",
            "in_which_gene",
            "from_species",
        ])
        files_list = os.listdir(BASE_PATH + os.sep + "temp_files")
        with tqdm(total=len(files_list)) as progress_bar:
            for file in files_list:
                all_df = pd.concat([all_df, pd.read_csv(BASE_PATH + os.sep + "temp_files" + os.sep + file)], ignore_index=True)
                progress_bar.update(1)
        all_df.to_csv(BASE_PATH + os.sep + file_name, index=False)
        print("All files merged successfully!")


if __name__ == '__main__':
    args_list = sys.argv[1:]
    if len(args_list) < 2:
        print("Warning: You must assign correct parameters!\n"
              "Usage:\n\tnss <SPECIES> <GENE_NAME>\n"
              "Note:\n\t<SPECIES> must be Latin language (e.g.: Mus_musculus, Homo_sapiens). \n"
              "\t<GENE_NAME> must be customized accurately!")
    else:
        species = args_list[0].replace("_", " ")
        gene_name = args_list[1].upper()
        get_snps = GetSNPs(species, gene_name)  # create object
        get_snps.get_snps()  # call method in object
        get_snps.merge("%s_%s_SNPs.csv" % (gene_name, species))
