
rm(list=ls(all=T))
cat("\014")
library(dplyr)
library(lubridate)
library(mailR)
setwd("/srv/shiny-server/btract/btract/data")
#------------------------------------------------------------------------------------------------------
bananadata <- read.csv("ArushaBananaData.csv")
todate <- Sys.Date()-1 # last day of the month
month_todate <- lubridate::month(as.Date(todate))
year_todate <- lubridate::year(as.Date(todate))

# ------- pollinations
this_month_pollinations <- dplyr::filter(bananadata, lubridate::month(bananadata$firstpollination_date)==month_todate &  lubridate::year(as.Date(bananadata$firstpollination_date))==year_todate)
n_pollination <- dim(this_month_pollinations)[1]
names(n_pollination) <- "Crosses"

#-------- bunches
this_month_bunches <- dplyr::filter(bananadata, lubridate::month(as.Date(bananadata$harvesting_date))==month_todate, lubridate::year(as.Date(bananadata$harvesting_date))==year_todate)
n_bunches <- dim(this_month_bunches)[1]
names(n_bunches) <- "Banana bunches"

#-------- seeds extracted
this_month_extracted_seeds <- dplyr::filter(bananadata,lubridate::month(as.Date(bananadata$seed_extraction_date))==month_todate, lubridate::year(as.Date(bananadata$seed_extraction_date))==year_todate)
seeds <- cbind(this_month_extracted_seeds$total_seeds,this_month_extracted_seeds$good_seeds,this_month_extracted_seeds$badseeds)
nseeds <- data.frame(colSums(seeds, na.rm = FALSE, dims = 1))
colnames(nseeds) <- "number"
rownames(nseeds) <- c("Total seeds","Good seeds","Bad seeds")
number_of_seeds <- t(nseeds)
total_seeds <- number_of_seeds[[1]]
names(total_seeds) <- "Total seeds extracted"

#--------embryo rescued
this_month_embryo_rescue <- dplyr::filter(bananadata, lubridate::month(as.Date(bananadata$rescue_date))==month_todate & lubridate::year(as.Date(bananadata$rescue_date))==year_todate)
n_embryo_rescue <- dim(this_month_embryo_rescue)[1]
names(n_embryo_rescue) <- "Embryo rescued"

rescueseeds <- cbind(this_month_embryo_rescue$good_seeds,this_month_embryo_rescue$badseeds)
nrescueseeds <- data.frame(colSums(rescueseeds, na.rm = FALSE, dims = 1))
number_of_embryo_seeds <- t(nrescueseeds)
colnames(number_of_embryo_seeds) <- c("Good seeds","Bad seeds")
rownames(number_of_embryo_seeds) <- "number"
good_seeds <- number_of_embryo_seeds[[1]]
names(good_seeds) <- "Good seeds"
bad_seeds <- number_of_embryo_seeds[[2]]
names(bad_seeds) <- "Bad seeds"

# -----------seeds_germinating_after_8weeks
seeds_after_8weeks <- read.csv("ArushaSeedsGerminatingAfter8Weeks.csv")
# ------------seeds germinated (after 8 weeks)
this_month_embryo_germinating_after_8weeks <- filter(seeds_after_8weeks, lubridate::month(as.Date(seeds_after_8weeks$seeds_germinating_after_8weeks_date))==month_todate, lubridate::year(as.Date(seeds_after_8weeks$seeds_germinating_after_8weeks_date))==year_todate)
n_seeds_after_8weeks <- dim(this_month_embryo_germinating_after_8weeks)[1]
names(n_seeds_after_8weeks) <- "Seeds germinating after 8 weeks"

# -----------plantlets dataset
plantlets <- read.csv("ArushaPlantlets.csv")

#---------Number in screenhouse
this_month_screenhse <- dplyr::filter(plantlets, lubridate::month(as.Date(plantlets$screenhse_transfer_date))==month_todate, lubridate::year(as.Date(plantlets$screenhse_transfer_date))==year_todate)
n_screenhse <- dim(this_month_screenhse)[1]
names(n_screenhse) <- "plantlets in screenhouse"

# ---------------Number in openfield
this_month_openfield <- dplyr::filter(plantlets, lubridate::month(as.Date(plantlets$date_of_transfer_to_openfield))==month_todate,lubridate::year(as.Date(plantlets$date_of_transfer_to_openfield))==year_todate)
n_openfield <- dim(this_month_openfield)[1]
names(n_openfield) <- "Plantlets in openfield"

# -----------contamination
contamination <- read.csv("ArushaContamination.csv")
this_month_contamination <- dplyr::filter(contamination, lubridate::month(as.Date(contamination$contamination_date))==month_todate, lubridate::year(as.Date(contamination$contamination_date))==year_todate)
n_contamination <- dim(this_month_contamination)[1]
names(n_contamination) <- "Contamination"

# -------------------------Monthly report
monthly_report <- data.frame(c(n_pollination, n_bunches, total_seeds, n_embryo_rescue, good_seeds, bad_seeds,n_seeds_after_8weeks,n_screenhse,n_openfield,n_contamination))
monthly_report = tibble::rownames_to_column(monthly_report)
names(monthly_report) <- c("Activity",paste0("Total number for ", month.abb[month(todate)],"-",year(todate)))
monthly_report <- dplyr::filter(monthly_report, monthly_report[,2]>0)
write.csv(monthly_report, file <- paste0("BTracT Monthly Report ", month.abb[month(todate)],"-",year(todate),".csv"), row.names = F)
  
# --------- email
send.mail(from = "******",
            to = c("*****"),
            subject = paste("BTracT Monthly report for ", month.abb[month(todate)],"-",year(todate)),
            body = paste("Attached is the monthly report for ", month.abb[month(todate)],"-",year(todate)), 
            smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "*****", passwd = "*****", ssl = TRUE),
            authenticate = TRUE,
            send = TRUE,
            attach.files = paste0("/srv/shiny-server/btract/btract/data/BTracT Monthly Report ", month.abb[month(todate)],"-",year(todate),".csv"),
            debug = F)
