rm(list=ls(all=T))
cat("\014")
setwd("/srv/shiny-server/btract/btract/data")
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(mailR))


status = read.csv("ArushaStatus.csv")

#----------------------------- EMAIL NOTIFICATIONS--------------------------------------------------------------------------------
today = Sys.Date()
# 1. status reported today

filter.status = status[,-1]
sdate = as.Date(filter.status$date)
filter.status.date = filter(filter.status, sdate==today)
if(dim(filter.status.date)[1]>0){
  write.csv(filter.status.date, file = "status_report.csv", row.names=F)

send.mail(from = "bananatrackertool@gmail.com",
          to =c("a.brown@cgiar.org","tm.shah@cgiar.org","m.karanja@cgiar.org"),
#	  to = ("m.karanja@cgiar.org"), 
          subject = paste("Arusha status report - ",Sys.time()),
          body =  paste("Attached is a list of accessions whose status was reported today - ", Sys.time()),
          smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "bananatrackertool@gmail.com", passwd = "Btract101", ssl = TRUE),
          authenticate = TRUE,
          send = TRUE,
          attach.files = "/srv/shiny-server/btract/btract/data/status_report.csv",
          debug = TRUE)

}else {
  status_report = character()
}
