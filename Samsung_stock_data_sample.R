library(stringr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
print(KOR_ticker$'종목코드'[1])

# 005930이어야 할 삼성전자의 티커가 5930
# str_pad() 함수를 사용해 6자리가 되지 않는 문자는 
# 왼쪽에 0을 추가해 강제로 6자리

KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

library(xts)

ifelse(dir.exists('data/KOR_price'), FALSE,
       dir.create('data/KOR_price'))

i = 1
name = KOR_ticker$'종목코드'[i]

# xts() 함수를 이용해 빈 시계열 데이터를 생성하며, 
# 인덱스는 Sys.Date()를 통해 현재 날짜를 입력
price = xts(NA, order.by = Sys.Date())
print(price)

print (name)
library(httr)
library(rvest)

# 네이버 시가총액 페이지에서 받아옴
url = paste0(
  'https://fchart.stock.naver.com/sise.nhn?symbol=',
  name,'&timeframe=day&count=500&requestType=0')
data = GET(url)
data_html = read_html(data, encoding = 'EUC-KR') %>%
  html_nodes('item') %>%
  html_attr('data') 

print(head(data_html))

library(readr)
# read_delim() 함수를 쓰면 구분자
price = read_delim(data_html, delim = '|')
print(head(price))

library(lubridate)
library(timetk)

price = price[c(1, 5)] 
price = data.frame(price)
colnames(price) = c('Date', 'Price')
price[, 1] = ymd(price[, 1])
price = tk_xts(price, date_var = Date)

print(tail(price))

write.csv(price, paste0('data/KOR_price/', name,
                        '_price.csv'))