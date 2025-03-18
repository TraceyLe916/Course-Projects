"""all packages needed in order to webscrape a dynamic website such as RMP
Includes pandas for converting the information gathered into a .csv file that is later used"""
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, StaleElementReferenceException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains
import pandas as pd

# attempts to disable any additional interferences that may slow sown the webscraping process
options = Options()
options.add_argument("--disable-notifications")
options.add_argument("--disable-gpu")
options.add_argument("enable-automation")
options.add_argument("--no-sandbox")
options.add_argument("--disable-extensions")
options.add_argument("--dns-prefetch-disable")
options.add_experimental_option("excludeSwitches", "disable-popup-blocking")

# the ? at the end can be changed to a number to webscrape a specific department
url = "https://www.ratemyprofessors.com/search/professors/1255?q=*&did=?"
driver = webdriver.Chrome()

while True:
    try:
        driver.get(url)
        break
    except TimeoutException:
        print("Your request to webscrape has timed out.")
        print("Trying again...")


# two time intervals to wait for before a timeout exception is raised
wait = WebDriverWait(driver, 20)
wait2 = WebDriverWait(driver, 5)


# closes cookies and ads that first appear when going into the website
try:
    cookies_exit = wait.until(EC.element_to_be_clickable((By.XPATH, '/html/body/div[5]/div/div/button')))
    cookies_exit.click()
except TimeoutException:
    print("No cookies")

try:
    close_ad = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="bx-close-inside-1177612"]')))
    close_ad.click()
except TimeoutException:
    print("Unable to close--Timed out")

# finds the show more button at the bottom
action = ActionChains(driver)
button = driver.find_element(By.XPATH, '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[4]/button')

# clicks the show more button until it is no longer visible
try:
    show_more = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[4]/button')))
    while show_more:
        action.move_to_element(button).click().perform()
        try:
            show_more = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[4]/button')))
        except StaleElementReferenceException:
            print("Stale Element Exception: Button no longer visible.")
            print("Moving onto scraping...")
            break
        except TimeoutException:
            print("Timeout Exception: Button is unable to be located.")
            print("Moving onto scraping...")
            break

except TimeoutException:
    print("Timed out waiting for page to load")

# finds the total number of professors in the department to be used in the for loop later
in_department = driver.find_elements(By.XPATH, '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[1]/div/h1')
total = in_department[0].text.split()
total_professors = int(total[0])

# list that stores the dictionaries that will be created in the for loop
reviews = []


for i in range(1, total_professors + 1):
    try:
        # finds prof name
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[1]')))
        name = driver.find_elements(By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[1]')

        # finds prof rating
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[1]/div/div[2]')))
        rating = driver.find_elements(By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[1]/div/div[2]')

        # finds prof department
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[2]/div[1]')))
        department = driver.find_elements(By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[2]/div[1]')

        # finds total number of ratings
        WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[1]/div/div[3]')))
        num_ratings = driver.find_elements(By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[1]/div/div[3]')

        # finds the percentage of students who would repeat the course
        WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[3]/div[1]/div')))
        would_repeat = driver.find_elements(By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[3]/div[1]/div')

        # finds the difficulty of the course rated out of 5
        WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[3]/div[3]/div')))
        difficulty = driver.find_elements(By.XPATH,
                '//*[@id="root"]/div/div/div[4]/div[1]/div[1]/div[3]/a[' + str(i) + ']/div/div[2]/div[3]/div[3]/div')

        # dictionary created with the professor data gathered
        professor_review = {'name': name[0].text.replace(",", ";"),
                            'department': department[0].text.replace(",", ";"),
                            'rating': rating[0].text,
                            'total_ratings': num_ratings[0].text,
                            'would take again': would_repeat[0].text,
                            'difficulty': difficulty[0].text}
        reviews.append(professor_review)

    except TimeoutException:
        break

# converts the RMP data into a .csv file
df = pd.DataFrame(reviews)
df.to_csv('professors.csv')

# little message at the end notifying the user that the webscraping was successful
print("File saved!")
print("Webscraping complete.")
