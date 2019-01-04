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

send.mail(from = "****@gmail.com",
          to =c("****","****"),
          subject = paste("Arusha status report - ",Sys.time()),
          body =  paste("Attached is a list of accessions whose status was reported today - ", Sys.time()),
          smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "email3@gmail.com", passwd = "*****", ssl = TRUE),
          authenticate = TRUE,
          send = TRUE,
          attach.files = "/srv/shiny-server/btract/btract/data/status_report.csv",
          debug = TRUE)

}else {
  status_report = character()
}
