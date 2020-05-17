#Get data from KPX

# Working Day 자동으로 세팅하기 
library(httr)
library(rvest)
library(stringr)

url = 'https://finance.naver.com/sise/sise_deposit.nhn'

biz_day = GET(url) %>%
  read_html(encoding = 'EUC-KR') %>%
  html_nodes(xpath =
               '//*[@id="type_1"]/div/ul[2]/li/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
  str_replace_all('\\.', '')

print(biz_day)


# 산업별 현황 데이터 크롤링 POST Request > CSV save
library(httr)
library(rvest)
library(readr)

# OTP 요청 보내고
gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'

gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = 'MKD/03/0303/03030103/mkd03030103',
  tp_cd = 'ALL',
  date = '20200515',
  lang = 'ko',
  pagePath = '/contents/MKD/03/0303/03030103/MKD03030103.jsp')

otp = POST(gen_otp_url, query = gen_otp_data) %>%
  read_html() %>%
  html_text()

# 실제로 데이터를 다운로드 하는 Part
down_url = 'http://file.krx.co.kr/download.jspx'
down_sector = POST(down_url, query = list(code = otp),
                   add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

print(down_sector)

ifelse(dir.exists('data'), FALSE, dir.create('data'))
write.csv(down_sector, 'data/krx_sector.csv')

# 개별지표 크롤링 (PBR, PER, EPS)

library(httr)
library(rvest)
library(readr)

gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = "MKD/13/1302/13020401/mkd13020401",
  market_gubun = 'ALL',
  gubun = '1',
  schdate = '20200515',
  pagePath = "/contents/MKD/13/1302/13020401/MKD13020401.jsp")

otp = POST(gen_otp_url, query = gen_otp_data) %>%
  read_html() %>%
  html_text()

down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code = otp),
                add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

print(down_ind)
write.csv(down_ind, 'data/krx_ind.csv')

# 중복데이터 제거
# 산업별 현황 및 개별지표의 중복데이터 제거

down_sector = read.csv('data/krx_sector.csv', row.names = 1,
                       stringsAsFactors = FALSE)
down_ind = read.csv('data/krx_ind.csv',  row.names = 1,
                    stringsAsFactors = FALSE)

print (names(down_sector))
print (names(down_ind))

intersect(names(down_sector), names(down_ind))

# 두 데이터에 공통적으로 없는 종목명, 즉 하나의 데이터에만 있는 종목
setdiff(down_sector[, '종목명'], down_ind[ ,'종목명'])

# merge() 함수는 by를 기준으로 두 데이터를 하나로 합치며, 
# 공통으로 존재하는 종목코드, 종목명을 기준
# 즉 두 데이터에 공통적으로 없는 종목명은 제외

KOR_ticker = merge(down_sector, down_ind,
                   by = intersect(names(down_sector),
                                  names(down_ind)),
                   all = FALSE
)

# 마이너스(-)를 붙여 내림차순 형태로 저장
KOR_ticker = KOR_ticker[order(-KOR_ticker['시가총액.원.']), ]
print(head(KOR_ticker))

# 스팩 및 우선주 항목 제외
library(stringr)
# 위 해당 항목 대상 추출
KOR_ticker[grepl('스팩', KOR_ticker[, '종목명']), '종목명']  
KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) != 0, '종목명']

# 위 대상 항목 제외 처리 
KOR_ticker = KOR_ticker[!grepl('스팩', KOR_ticker[, '종목명']), ]  
KOR_ticker = KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) == 0, ]


