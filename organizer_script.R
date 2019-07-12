cat("\014")
rm(list=ls(all=T))
setwd("/srv/shiny-server/btract/btract/data")

# LOAD REQUIRED PACKAGES
# function
ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

# usage
packages <- c("dplyr","tidyr","stringr","stringi","httr","httpuv","jsonlite","RCurl","data.table","plyr")
ipak(packages)
library(ona)

## Get data from ona
banana = onaDownload("formID","ona_account_name","username","passwd") # contact admin
site = dplyr::select(banana, ends_with("Location")) %>%
  tidyr::gather(area, site, ends_with("Location"), na.rm=T)

## ORGANIZE DATA
# FLOWERING DATA
flowerID = dplyr::select(banana, contains("floweringID")) %>%
  tidyr::gather(flowering, flowerID, ends_with("floweringID"), na.rm = T) %>%
  dplyr::select(flowerID) %>%
  dplyr::mutate(flower = flowerID)

flowerName = dplyr::select(banana, ends_with("flowerName")) %>%
  tidyr::gather(flower, accession_name, ends_with("flowerName"), na.rm=T) %>%
  dplyr::select(accession_name)

pSex <- dplyr::select(banana, ends_with("plantSex")) %>%
  tidyr::gather(psex, sex, ends_with("plantSex"), na.rm = T) %>% dplyr::select(sex)
if(dim(flowerID)[1]>0){
  floweringDate <- dplyr::select(banana, ends_with("flowering_date")) %>%
    tidyr::gather(date, flowering_date, ends_with("flowering_date"), na.rm = T) %>% dplyr::select(flowering_date)
}else {
  floweringDate = data.frame(flowering_date=character())
}
flowering = data.frame(c(flowerID, flowerName, pSex, floweringDate))

if(nrow(flowering)>0){
flowering$location = "Arusha"
} else { 
  flowering$location = character()
  }

flowering = dplyr::filter(flowering, flowering_date>=(Sys.Date() - 10))
flowering$flowering_date = as.Date(as.character(flowering$flowering_date, format="%Y/%m/%d"))

flowering <- flowering[order(flowering$flowering_date),]

#------------------write flowering data------------------------------------
write.csv(flowering, file = "ArushaFlowering.csv", row.names = F)
saveRDS(flowered, file = "ArushaAllFlowering.rds")
# -----------------------------------------------------------------------------------------------------------------------------------------
# FIRST POLLINATION
FPOLLN = dplyr::select(banana, contains("FirstPollination"))
motherID = dplyr::select(FPOLLN, ends_with("femaleID"))%>%
  tidyr::gather("ID", "femaleID", ends_with("femaleID"), na.rm=T) %>% dplyr::select("femaleID") 
motherID = tibble::rownames_to_column(motherID)
mothername = dplyr::select(FPOLLN, ends_with("FemaleName"))%>%
  tidyr::gather("name", "motherAccessionName", ends_with("FemaleName"), na.rm=T) %>% dplyr::select("motherAccessionName")
mothername = tibble::rownames_to_column(mothername)
cycle  = dplyr::select(FPOLLN, ends_with("FirstPollination.cycleID")) %>%
  tidyr::gather("ID", "cycle", ends_with("FirstPollination.cycleID"), na.rm=T) %>% dplyr::select("cycle")
cycle = tibble::rownames_to_column(cycle)
fatherID = dplyr::select(FPOLLN, ends_with("FirstPollination.maleID"))%>%
  tidyr::gather("name", "fatherID", ends_with("FirstPollination.maleID"), na.rm=T) %>% dplyr::select("fatherID")
fatherID = tibble::rownames_to_column(fatherID)
fathername = dplyr::select(FPOLLN, ends_with("maleAccName"))%>%
  tidyr::gather("name", "fatherAccessionName", ends_with("maleAccName"), na.rm=T) %>% dplyr::select("fatherAccessionName")
fathername = tibble::rownames_to_column(fathername)
firstpollination_date <- dplyr::select(FPOLLN, ends_with("firstpollination_date")) %>%
  tidyr::gather("date", "firstpollination_date", ends_with("firstpollination_date"), na.rm = T) %>% dplyr::select("firstpollination_date")
firstpollination_date = tibble::rownames_to_column(firstpollination_date)
crossID <- dplyr::select(FPOLLN, ends_with("print_crossBarcode.crossID")) %>%
  tidyr::gather("ID", "crossnumber", ends_with("print_crossBarcode.crossID"), na.rm = T) %>% 
  dplyr::select("crossnumber")
crossID = tibble::rownames_to_column(crossID)
crossesDT = list(crossID, motherID, mothername, fatherID, fathername, firstpollination_date)#cycle,
crossesDF = Reduce(function(x,y) merge(x,y, all = T, by= "rowname"), crossesDT)
crossesDF$crossID = crossesDF$crossnumber
crossesDF$rowname = NULL

# crossesDF$cycle = as.integer(substr(crossesDF$crossnumber,18,18))
crossesDF$cycle = as.integer(
  substr(crossesDF$crossnumber, data.frame(stringr::str_locate(pattern = "C", crossesDF$crossnumber))$start+1, 
       data.frame(stringr::str_locate(pattern = "C", crossesDF$crossnumber))$start+1)
)

firstpollination = crossesDF[complete.cases(crossesDF),]
firstpollination = filter(crossesDF, !is.na(cycle)) # Remove empty cycles

# data correction for errors made on 2018-05-22
DT20180522 = filter(firstpollination, firstpollination_date == "2018-05-22" & cycle == 1)
DT20180522$crossnumber = gsub("C1","C2", DT20180522$crossnumber)
DT20180522$crossID = gsub("C1","C2", DT20180522$crossID)
DT20180522$cycle = gsub(1, 2, DT20180522$cycle)

first.pollination = filter(firstpollination, firstpollination_date!='2018-05-22')
firstpollination = rbind(first.pollination, DT20180522)

# Replace PlotID with PlotName where ID used was PlotID 
nm_pollination_block = read.csv("NM_Pollination_block.csv")[,-3] # Trial Data
colnames(nm_pollination_block) = c("mother","femaleID") 
nm_pollination_block$femaleID = as.character(nm_pollination_block$femaleID)

firstpollination_PlotID = filter(firstpollination, str_length(femaleID) < 10) # set with only PlotID
firstpollination_PlotName = filter(firstpollination, str_length(femaleID) > 10) # set with only PlotName
colnames(firstpollination_PlotName)[5] <- 'father'
firstpollination_PlotName$mother = firstpollination_PlotName$femaleID
firstpollination_PlotName$fatherAccessionName = firstpollination_PlotName$father
firstpollination_PlotName$father <- NULL
firstpollination_FemalePlotName = dplyr::left_join(firstpollination_PlotID, nm_pollination_block, by="femaleID")
colnames(nm_pollination_block) = c("father","fatherID") 
firstpollination_FemaleAndMalePlotName = dplyr::left_join(firstpollination_FemalePlotName, nm_pollination_block, 
                                                          by="fatherID")
firstpollination_FemaleAndMalePlotName$fatherID <- firstpollination_FemaleAndMalePlotName$father
firstpollination_FemaleAndMalePlotName$father <- NULL

firstpollination = rbind(firstpollination_PlotName,firstpollination_FemaleAndMalePlotName)
firstpollination$femaleID = NULL
firstpollination$femaleID = firstpollination$mother
nm_pollination_block2_crosses = read.csv("/srv/shiny-server/btract/btract/data/NM_Pollination_Block_2_Crosses.csv") %>%
   dplyr::rename(
    crossnumber = cross_name,
    motherAccessionName = female_parent,
    fatherAccessionName = male_parent,
    firstpollination_date = First_Pollination_Date
  ) %>%
  dplyr::select(-ends_with("_plot"), -cross_type)
nm_pollination_block2_crosses$firstpollination_date = as.Date(nm_pollination_block2_crosses$firstpollination_date)
firstpollination = plyr::rbind.fill(firstpollination, nm_pollination_block2_crosses)

#**************************************************
ncrosses = data.table::data.table(firstpollination[!duplicated(firstpollination$crossnumber), ])
ncrosses.female = as.data.frame(ncrosses[,number := 1:.N, by = mother])
crosses_per_female = reshape(ncrosses.female, direction = "wide", idvar = "mother", timevar = "number")
crosses_per_female = crosses_per_female %>%
  dplyr::select(mother,starts_with("crossnumber.")) %>%
  janitor::remove_empty()
crosses_per_female$number_crosses = rowSums(!is.na(crosses_per_female[,c(2:ncol(crosses_per_female))]))
colnames(crosses_per_female) = gsub("\\.","_", names(crosses_per_female))
write.csv(crosses_per_female, file = "ArushaCrossesPerFemalePlot.csv", row.names = F)
janitor::r

#******************************************************* END

# Repeat pollination
rpt = dplyr::select(banana,contains("repeatpollination"))
getCrossID = dplyr::select(rpt, ends_with("getCrossID")) %>%
  tidyr::gather(cross, crossnumber, ends_with("getCrossID"), na.rm = T) %>% dplyr::select(crossnumber)

rptMale_AccName = dplyr::select(rpt, ends_with("getRptMaleAccName")) %>%
  tidyr::gather(rptMale, Male, ends_with("getRptMaleAccName"), na.rm = T) %>% dplyr::select(Male)

if(dim(getCrossID)[1]>0){
  rptPollnDate = dplyr::select(rpt, ends_with("rptpollination_date")) %>%
    tidyr::gather(date, repeatPollinationDate, ends_with("rptpollination_date"), na.rm = T) %>% dplyr::select(repeatPollinationDate)
  
}else {
  rptPollnDate = data.frame(repeatPollinationDate=character())
}
getMotherName = dplyr::select(rpt, ends_with("getRptFemaleAccName"))%>%
  tidyr::gather(mother, motherName, ends_with("getRptFemaleAccName"), na.rm = T) %>% dplyr::select(motherName)

repeatdf <- as.data.frame(c(getCrossID,getMotherName, rptMale_AccName, rptPollnDate))
repeatData = dplyr::select(repeatdf,"crossnumber","motherName","Male","repeatPollinationDate")
colnames(repeatData) = c("crossnumber","mother_accession","father_clone","repeatpollination_date.1")
saveRDS(repeatData, file = "ArushaAllRepeatpollination.rds")

if(dim(repeatData)[1]>0){
  colnames(repeatData) = c("crossnumber","mother_accession","father_clone","repeatpollination_date")
  repeatdt = data.table(repeatData[,-c(2:3)])
  repeatDT = as.data.frame(repeatdt[,number := 1:.N, by = crossnumber])
  repeatDTwide = reshape(repeatDT,direction = "wide", idvar = "crossnumber", timevar = "number")
  repeatID = data.frame(repeatDTwide$crossnumber)
  colnames(repeatID) <- "repeatpollinationID"
  repeatDT.wide <- data.frame(c(repeatID, repeatDTwide))
  repeatDT.wide$location = "Arusha"
} else {
  repeatDT.wide = repeatData
  repeatDT.wide$location = character()
}
# HARVESTING
harVEST = dplyr::select(banana, contains("harvesting"))
harvestedID = dplyr::select(harVEST, ends_with("harvestID")) %>%
  tidyr::gather(id, crossnumber, ends_with("harvestID"),na.rm = T)
harvestID <- data.frame(harvestedID$crossnumber)
if(dim(harvestID)[1]>0){
  harvestdate = dplyr::select(harVEST, ends_with("harvesting_date")) %>%
    tidyr::gather(date, harvesting_date, na.rm = T) %>% dplyr::select(harvesting_date)
  harvested = as.data.frame(c(harvestedID, harvestID,harvestdate))
  harvested$pollinationDATE <- NULL
  harvested$harvestDATE <- NULL
  harvested$X_submission_time <- NULL
  harvestingdf = dplyr::select(harvested,crossnumber,harvestedID.crossnumber, harvesting_date)
  colnames(harvestingdf) = c("crossnumber", "harvestID", "harvesting_date")
  
}else {
  harvestDATE = data.frame(harvesting_date=character())
  harvested = as.data.frame(cbind(harvestedID, harvestID,harvestDATE,days_to_maturity=character()))
  harvestingdf = dplyr::select(harvested,crossnumber,harvestedID.crossnumber, harvesting_date,days_to_maturity)
  colnames(harvestingdf) = c("crossnumber", "harvestID", "harvesting_date","days_to_maturity")
}


# EXTRACTION
EXTRACTION = dplyr::select(banana, contains("seedExtraction"))
extractid = dplyr::select(EXTRACTION, ends_with("extractionID")) %>%
  tidyr::gather(extract, crossnumber,ends_with("extractionID"), na.rm = T)
extractID <- data.frame(extractid$crossnumber)
total = dplyr::select(banana, ends_with("totalSeedsExtracted")) %>% 
  tidyr::gather(total, total_seeds, ends_with("totalSeedsExtracted"), na.rm = T)
extractdate = dplyr::select(EXTRACTION, ends_with("extraction_date")) %>% 
  tidyr::gather(date, seed_extraction_date, ends_with("extraction_date"),na.rm = T)
dateExtract = str_replace(extractdate$seed_extraction_date, "-", "/")
dateExtrd = str_replace(dateExtract, "-", "/")

harvestDate = dplyr::select(banana, ends_with("getHarvest_date")) %>%
  tidyr::gather(date, harvestDate, ends_with("getHarvest_date"), na.rm = T) %>% dplyr::select(harvestDate)
hDate = str_replace(harvestDate$harvestDate, "-", "/")
harvestD = str_replace(hDate, "-", "/")
harvest2extraction = data.frame(dateExtrd, harvestD)
harvest2extraction$days_harvest_extraction = ymd(dateExtrd)-ymd(harvestD)

extracted = as.data.frame(c(extractid, extractID,extractdate, total, harvest2extraction))
extractiondt = dplyr::select(extracted,crossnumber,extractid.crossnumber, seed_extraction_date, total_seeds, days_harvest_extraction)
colnames(extractiondt) = c("crossnumber", "extractID","seed_extraction_date", "total_seeds","days_harvest_extraction")

# check for duplicate entries, keep entry with highest seeds
#x = extractiondt[order(extractiondt$crossnumber, extractiondt$total_seeds), ] #sort by id and total seeds
#y = filter(x, duplicated(crossnumber) == "TRUE")
# extractiondf = y[!duplicated(y$crossnumber), ]  

x <- extractiondt[order(extractiondt$crossnumber, -abs(extractiondt$total_seeds) ), ] ### sort first
extractiondf <- x[ !duplicated(x$crossnumber), ]  ### Keep highest

## LAB
# RESCUE
good = dplyr::select(banana, ends_with("goodSeeds")) %>%
  tidyr::gather(good, good_seeds,ends_with("goodSeeds"), na.rm = T)
bad = dplyr::select(banana, ends_with("badSeeds")) %>%
  tidyr::gather(bad, bad_seeds, ends_with("badSeeds"),na.rm = T)
RESCUED = dplyr::select(banana, contains("embryoRescue"))
rescueid = dplyr::select(RESCUED, ends_with("embryorescueID"))%>%
  tidyr::gather(id, crossnumber,ends_with("embryorescueID"), na.rm = T)
rescueID <- data.frame(rescueid$crossnumber)
rescueseeds = dplyr::select(RESCUED, ends_with("embryorescue_seeds")) %>%
  tidyr::gather(seeds, number_rescued, ends_with("embryorescue_seeds"),na.rm = T)
if(dim(rescueid)[1]>0){
  rescuedate = dplyr::select(RESCUED, ends_with("embryorescue_date"))%>%
    tidyr::gather(id, rescue_date,ends_with("embryorescue_date"), na.rm = T)
  rescuedate$id <- NULL
  dateEXTRD = dplyr::select(RESCUED, ends_with("extracted_date")) %>%
    tidyr::gather(date, extract_date, ends_with("extracted_date"), na.rm = T)
  date_Resc = str_replace(rescuedate$rescue_date, "-", "/")
  dateResc = str_replace(date_Resc, "-", "/")
  date_EXTRD = str_replace(dateEXTRD$extract_date, "-", "/")
  dateEXTRD = str_replace(date_EXTRD, "-", "/")
  Extract2Rescue = data.frame(dateEXTRD, dateResc)
  Extract2Rescue$days_extraction_rescue <- as.Date(as.character(Extract2Rescue$dateResc), format="%Y/%m/%d")-
    as.Date(as.character(Extract2Rescue$dateEXTRD), format="%Y/%m/%d")
  Extract2Rescue$dateEXTRD <- NULL
  Extract2Rescue$dateResc <-NULL
  rescued = as.data.frame(c(rescueid,rescueID,good, bad, rescuedate, rescueseeds, Extract2Rescue))
  rescuingdf = dplyr::select(rescued, crossnumber, rescueid.crossnumber, good_seeds, bad_seeds, number_rescued, rescue_date, days_extraction_rescue)
  colnames(rescuingdf) = c("crossnumber", "rescueID","good_seeds","badseeds","number_rescued", "rescue_date", "days_extraction_rescue")
}else {
  rescuingdf = data.frame(cbind(crossnumber=character(), rescueID=character(),good_seeds=character(),badseeds=character(),number_rescued=character(), rescue_date=character(), days_extraction_rescue=character()))
}

# 2 WEEKS GERMINATION
week2Germination = dplyr::select(banana, contains("embryo_germinatn_after_2wks") )
twowksID = dplyr::select(week2Germination,ends_with("germinating_2wksID")) %>%
  tidyr::gather(germinating, crossnumber, ends_with("germinating_2wksID"), na.rm = T)
week2ID <- data.frame(twowksID$crossnumber)
active2wks = dplyr::select(week2Germination, ends_with("actively_2wks")) %>%
  tidyr::gather(active, actively_germination_after_two_weeks, ends_with("actively_2wks"),na.rm = T)
if(dim(week2ID)[1]>0){
  twowksDate = dplyr::select(week2Germination, ends_with("2wks_date")) %>% 
    tidyr::gather(date, germination_after_2weeks_date, ends_with("2wks_date"),na.rm = T)
  twowksDate$date <- NULL
}else {
  twowksDate = data.frame(germination_after_2weeks_date=character())
}

date2wk = str_replace(twowksDate$germination_after_2weeks_date, "-", "/")
date2wks = str_replace(date2wk, "-", "/")
rescDate = dplyr::select(week2Germination, ends_with("rescued_date")) %>%
  tidyr::gather(date, rescuedDate, ends_with("rescued_date"), na.rm = T)
dateERescue = str_replace(rescDate$rescuedDate, "-", "/")
dateERescued = str_replace(dateERescue, "-", "/")

Rescue_2wks = data.frame(date2wks, dateERescued)
Rescue_2wks$days_rescue_2wksGermination <- as.Date(as.character(Rescue_2wks$date2wks), format="%Y/%m/%d")-
  as.Date(as.character(Rescue_2wks$dateERescued), format="%Y/%m/%d")
Rescue_2wks$date2wks <- NULL
Rescue_2wks$dateERescued <- NULL
germination2weeks = as.data.frame(c(twowksID, week2ID, twowksDate, active2wks, Rescue_2wks))
germination2weeksdf = dplyr::select(germination2weeks,crossnumber,twowksID.crossnumber, germination_after_2weeks_date, actively_germination_after_two_weeks, days_rescue_2wksGermination)
colnames(germination2weeksdf) = c("crossnumber", "week2ID","germination_after_2weeks_date", 
                                  "actively_germination_after_two_weeks","days_rescue_2weeksGermination")

# 8 weeks GERMINATION
week8 = dplyr::select(banana, contains("embryo_germinatn_after_8weeks"))
week8ID = dplyr::select(week8, ends_with("germinating_8weeksID"))%>%
  tidyr::gather(germinating, crossnumber, ends_with("germinating_8weeksID"),na.rm = T)
week8.ID <- data.frame(week8ID$crossnumber)
active8weeks = dplyr::select(week8, ends_with("actively_8weeks")) %>%
  tidyr::gather(active, actively_germination_after_8weeks, ends_with("actively_8weeks"),na.rm = T)
if(dim(week8ID)[1]>0){
  week8Date = dplyr::select(week8, ends_with("germinating_8weeks_date")) %>%
    tidyr::gather(date, germination_after_8weeks_date, ends_with("germinating_8weeks_date"),na.rm = T)
  week8Date$date <- NULL
}else {
  week8Date = data.frame(germination_after_8weeks_date=character())
}

date8weeks = str_replace(week8Date$germination_after_8weeks_date, "-", "/")
date.8weeks = str_replace(date8weeks, "-", "/")
germ2wks_date = dplyr::select(week8, ends_with("germinated_2wksdate")) %>%
  tidyr::gather(date, germ2wksdate, ends_with("germinated_2wksdate"), na.rm = T)
germ2wkDate = str_replace(germ2wks_date$germ2wksdate, "-","/")
germinated2wksDate = str_replace(germ2wkDate,"-","/")
Germination_2wks_8weeks = data.frame(germinated2wksDate, date.8weeks)
Germination_2wks_8weeks$days_2weeks_8weeks_Germination <- as.Date(as.character(Germination_2wks_8weeks$date.8weeks), format="%Y/%m/%d")-
  as.Date(as.character(Germination_2wks_8weeks$germinated2wksDate), format="%Y/%m/%d")
Germination_2wks_8weeks$germinated2wksDate <- NULL
Germination_2wks_8weeks$dateOneM <- NULL
germination8weeks = as.data.frame(c(week8ID, week8.ID, week8Date, active8weeks, Germination_2wks_8weeks))
germination8weeksdf = dplyr::select(germination8weeks, crossnumber,week8ID.crossnumber, germination_after_8weeks_date, actively_germination_after_8weeks, days_2weeks_8weeks_Germination)
colnames(germination8weeksdf) = c("crossnumber", "week8ID","germination_after_8weeks_date",
                                  "actively_germination_after_8weeks", "days_2weeksGermination_8weeksGermination")

#--------------------BANANADATA--------------------------------------------------------------------------------------
allbanana = list(firstpollination,repeatDT.wide, 
                 harvestingdf, extractiondf, rescuingdf, germination2weeksdf,germination8weeksdf)                   
bananadat = Reduce(function(x,y) merge(x,y, all = T, by= "crossnumber"), allbanana)
bananadata = dplyr::select(bananadat, crossnumber, everything())
bananadata1 = bananadata[order(bananadata$mother, -rank(bananadata$cycle)), ]
if(nrow(bananadata1)>0){
bananadata1$location = "Arusha"
} else {bananadata1$location = character() }
write.csv(bananadata1, file = "ArushaBananaData.csv", row.names = F)
saveRDS(bananadata1, file = "ArushaBananaData.rds")

#---------Seeds germinating after 8 weeks---------------------------------------------------------------------------------------------
if(dim(germination8weeksdf)[1]>0){
  seeds_germinating_after_8weeks = dplyr::select(week8,ends_with("activeID"))%>%
    tidyr::gather(id, seed_id, ends_with("activeID"), na.rm=T)%>% dplyr::select(seed_id)
  seeds_germinating_after_8weeks$id = seeds_germinating_after_8weeks$seed_id
  cross_seedID = data.frame(str_sub(seeds_germinating_after_8weeks$id, 1, str_length(seeds_germinating_after_8weeks$id)-2))
  colnames(cross_seedID) = "crossnumber"
  seed_date = dplyr::select(week8, ends_with("active_date"))%>%
    tidyr::gather(mo, seeds_germinating_after_8weeks_date, ends_with("active_date"), na.rm = T)%>% dplyr::select(seeds_germinating_after_8weeks_date)
  getMother = dplyr::select(week8, ends_with("active_mother"))%>%
    tidyr::gather(mo, mother, ends_with("active_mother"), na.rm = T)%>% dplyr::select(mother)
  getFather = dplyr::select(week8, ends_with("active_father"))%>%
    tidyr::gather(fa, father, ends_with("active_father"), na.rm = T)%>% dplyr::select(father)
  seeds_data = data.frame(c(cross_seedID,seeds_germinating_after_8weeks, getMother, getFather,seed_date))
  seeds_data$location = "Arusha"
} else{
  seeds_data = data.frame(location = character(), crossnumber=character(), seed_id=character(),seeds_germinating_after_8weeks=character(), mother =character(),father=character(),seeds_germinating_after_8weeks_date=character())
}
#---------------------------------------------------------------------------------------------------------------------------------
write.csv(seeds_data,file = "ArushaSeedsGerminatingAfter8Weeks.csv", row.names = F)
saveRDS(seeds_data,file = "ArushaSeedsGerminatingAfter8Weeks.rds")

#-------------subculturing---------------------------------------------------------------------------------------------------------
subs = dplyr::select(banana, ends_with("subcultureID"))%>%
  tidyr::gather(subs, seedID, ends_with("subcultureID"), na.rm = T)
subs$subs <- NULL
if(dim(subs)[1]>0){
  subMother = dplyr::select(banana, ends_with("multiplication_mother"))%>%
    tidyr::gather(mo, mother, ends_with("multiplication_mother"), na.rm = T)
  subMother$mo <- NULL
  subFather = dplyr::select(banana, ends_with("multiplication_father"))%>%
    tidyr::gather(fa, father, ends_with("multiplication_father"), na.rm = T)
  subFather$fa <- NULL
  subID = dplyr::select(banana, ends_with("multiplicationID"))%>%
    tidyr::gather(id, plantletID, ends_with("multiplicationID"), na.rm = T)
  subID$id <- NULL
  subID$subID <- subID$plantletID
  seedID = data.frame(stri_sub(subID$plantletID, 1, -6))
  colnames(seedID) = "seedID"
  crossID = data.frame(stri_sub(subID$plantletID, 1, -8))
  colnames(crossID) = "crossnumber"
  subdate = dplyr::select(banana, ends_with("multiplication_date"))%>%
    tidyr::gather(date, subculture_date, ends_with("multiplication_date"), na.rm = T)
  subdate$date = NULL
  subcultures = data.frame(cbind(crossID, seedID,subID,subMother,subFather, subdate))
  subculturingdf = subcultures
}else{
  subculturingdf = data.frame(cbind(crossnumber=character(),seedID=character(),plantletID=character(),subID=character(),mother=character(),father=character(), subculture_date=character()))
}


#----------------------

# ROOTING
ROOT = dplyr::select(banana, contains("rooting"))
rootid = dplyr::select(ROOT, ends_with("rootingID")) %>% 
  tidyr::gather(id, plantletID, ends_with("rootingID"),na.rm = T)
rootid$rootID <- rootid$plantletID
if(dim(rootid)[1]>0){
  rootdate = dplyr::select(ROOT, ends_with("rooting_date")) %>%
    tidyr::gather(date, rooting_date, ends_with("rooting_date"),na.rm = T)
  rootDate = str_replace(rootdate$rooting_date, "-","/")
  rDate = str_replace(rootDate,"-","/")
} else{
  rootdate = data.frame(rooting_date=character())
}
rootin = as.data.frame(c(rootid, rootdate))
rootingdf = dplyr::select(rootin, plantletID, rootID, rooting_date)
colnames(rootingdf) = c("plantletID","rootID", "date_rooting")

# SCREEN HOUSE
HOUSE = dplyr::select(banana, contains("screenhouse"))
transferscrnhseid = dplyr::select(HOUSE, ends_with("screenhseID")) %>%
  tidyr::gather(id, plantletID,ends_with("screenhseID"), na.rm = T)
transferscrnhseID <- data.frame(transferscrnhseid$plantletID)
if(dim(transferscrnhseid)[1]>0){
  transferdate = dplyr::select(HOUSE, ends_with("screenhse_transfer_date")) %>% 
    tidyr::gather(date, date_of_transfer_to_screenhse,ends_with("screenhse_transfer_date"), na.rm = T)
}else {
  transferdate = data.frame(date_of_transfer_to_screenhse=character())
}

dateHSE = str_replace(transferdate$date_of_transfer_to_screenhse, "-", "/")
dateHSED = str_replace(dateHSE, "-", "/")
rootedDate = dplyr::select(HOUSE, ends_with("rooted_date")) %>%
  tidyr::gather(date, rootdate, ends_with("rooted_date"), na.rm = T)
dateRTD = str_replace(rootedDate$rootdate, "-", "/")
dateROOTED = str_replace(dateRTD, "-", "/")
rooting2Screenhse = data.frame(dateROOTED, dateHSED)
rooting2Screenhse$days_rooting_screenhse <- as.Date(as.character(rooting2Screenhse$dateHSED), format="%Y/%m/%d")-
  as.Date(as.character(rooting2Screenhse$dateROOTED), format="%Y/%m/%d")
rooting2Screenhse$dateROOTED <- NULL
rooting2Screenhse$dateHSED <- NULL
transferscreenhse = as.data.frame(c(transferscrnhseid, transferscrnhseID, transferdate, rooting2Screenhse))
screenhsedf = dplyr::select(transferscreenhse, plantletID,transferscrnhseid.plantletID, date_of_transfer_to_screenhse,days_rooting_screenhse)      #transfer to screenhsedf
colnames(screenhsedf) = c("plantletID", "transferscrnhseID","screenhse_transfer_date","days_rooting_screenhse")

# Hardening
HARD = dplyr::select(banana, contains("hardening"))
hardenedid = dplyr::select(HARD, ends_with("hardeningID")) %>%
  tidyr::gather(id, plantletID, ends_with("hardeningID"),na.rm = T)
hardenID <- data.frame(hardenedid$plantletID)
if(dim(hardenID)[1]>0){
  hardeneddate = dplyr::select(HARD, ends_with("hardening_date")) %>% 
    tidyr::gather(date, hardening_date,ends_with("hardening_date"), na.rm = T)
  hardeneddate$date <- NULL
}else {
  hardeneddate = data.frame(hardening_date=character())
}

dateHARD = str_replace(hardeneddate$hardening_date, "-", "/")
dateHARDENED = str_replace(dateHARD, "-", "/")

screenhseDATE = dplyr::select(HARD, ends_with("screenhsed_date")) %>%
  tidyr::gather(date, screendate, ends_with("screenhsed_date"), na.rm = T)
dateSHSE = str_replace(screenhseDATE$screendate, "-", "/")
dateSHSED = str_replace(dateSHSE, "-", "/")
screenhse2Hardening = data.frame(dateHARDENED, dateSHSED)
screenhse2Hardening$days_scrnhse_hardening <- as.Date(as.character(screenhse2Hardening$dateHARDENED), format="%Y/%m/%d")-
  as.Date(as.character(screenhse2Hardening$dateSHSED), format="%Y/%m/%d")
screenhse2Hardening$dateHARDENED <- NULL
screenhse2Hardening$dateSHSED <- NULL
hardening = as.data.frame(c(hardenedid,hardenID, hardeneddate, screenhse2Hardening))
hardeningdf = dplyr::select(hardening,plantletID, hardenedid.plantletID,hardening_date, days_scrnhse_hardening)  ## hardening
colnames(hardeningdf) = c("plantletID","hardenID", "hardening_date", "days_scrnhse_hardening")

# Open field
OPEN = dplyr::select(banana, contains("transplant_openfield"))
openfield_ID = dplyr::select(OPEN,ends_with("openfieldID")) %>%
  tidyr::gather(id, plantletID,ends_with("openfieldID"), na.rm = T)
openfieldID <- data.frame(openfield_ID$plantletID)
if(dim(openfieldID)[1]>0){
  opendate = dplyr::select(OPEN, ends_with("transplanting_date")) %>%
    tidyr::gather(date, date_of_transfer_to_openfield, ends_with("transplanting_date"),na.rm = T)
}else {
  opendate = data.frame(date_of_transfer_to_openfield=character())
}
dateOPEN = str_replace(opendate$date_of_transfer_to_openfield, "-", "/")
dateOPENFD = str_replace(dateOPEN, "-", "/")

dateHardd = dplyr::select(OPEN, ends_with("hardened_date"))%>%
  tidyr::gather(date, hard_date, ends_with("hardened_date"), na.rm = T)
dateHarder = str_replace(dateHardd$hard_date, "-","/")
dateHD = str_replace(dateHarder, "-","/")
harden2OField = data.frame(dateOPENFD, dateHD)
harden2OField$days_hardening_openfield <- as.Date(as.character(harden2OField$dateOPENFD), format="%Y/%m/%d")-
  as.Date(as.character(harden2OField$dateHD), format="%Y/%m/%d")
harden2OField$dateOPENFD <- NULL
harden2OField$dateHD <- NULL
openfieldtransfer = as.data.frame(c( openfield_ID,openfieldID, opendate, harden2OField))
openfieldtransferdf = dplyr::select(openfieldtransfer, plantletID,openfield_ID.plantletID,date_of_transfer_to_openfield, days_hardening_openfield) #to open field
colnames(openfieldtransferdf) = c("plantletID", "openfieldID","date_of_transfer_to_openfield",
                                  "days_hardening_openfield")
#--------------MERGE PLANTLETS DETAILS ------------------------------------------------------------------------------------------------------
allplantlets = list(subculturingdf, rootingdf, screenhsedf, hardeningdf, openfieldtransferdf)
merge_plantlets = Reduce(function(x,y) merge(x,y, all=T, by = "plantletID"), allplantlets)
plantsDF = dplyr::select(merge_plantlets, plantletID, everything())
if(nrow(plantsDF)>0){
plantsDF$location = "Arusha"
} else {plantsDF$location = character()}
write.csv(plantsDF, file = "ArushaPlantlets.csv", row.names = F)
saveRDS(plantsDF, file = "ArushaPlantlets.rds")

#----------------------------STATUS------------------------------------------------------------------------------------------
#----------------STOLEN
# mother
statuses = dplyr::select(banana,contains("plantstatus"))
stolen.type = dplyr::select(statuses, ends_with("plant_status")) %>%
  tidyr::gather(type, status, ends_with("plant_status"), na.rm = T) %>%
  filter(status=="bunch_stolen") %>%
  tibble::rownames_to_column()
stolen.type$type <- NULL
mother.stolenID = dplyr::select(statuses, ends_with("stolen_statusID"))%>%
  tidyr::gather(mother.status, motherID, ends_with("stolen_statusID"), na.rm = T) %>%
  dplyr::select(motherID) %>%
  tibble::rownames_to_column()

stolen_image = dplyr::select(banana, ends_with("stolen_image")) %>%
  tidyr::gather(stolen_image, image, ends_with("stolen_image"), na.rm = T) %>%
  dplyr::select(image) %>%
  tibble::rownames_to_column()

if(dim(stolen.type)[1]>0){
  stolendate = dplyr::select(statuses, ends_with("stolen_date")) %>%
    tidyr::gather(date, stolen_date, ends_with("stolen_date"), na.rm = T) %>% 
    dplyr::select(stolen_date) %>%
    tibble::rownames_to_column()
} else {
  stolendate = data.frame(stolen_date=character())
}
stolen_notes = dplyr::select(statuses, ends_with("stolen_comments"))%>%
  tidyr::gather(note, notes, ends_with("stolen_comments"), na.rm = T) %>%
  dplyr::select(notes) %>%
  tibble::rownames_to_column()

# stolen_statusLocAccName = dplyr::select(statuses, ends_with("stolen_statusLocAccName"))%>%
#   tidyr::gather(loc, AccessionName, ends_with("stolen_statusLocAccName"), na.rm = T)
# stolen_statusLocAccName$loc <- NULL
# stolen_statusLocLocationName = dplyr::select(statuses, ends_with("stolen_statusLocLocationName"))%>%
#   tidyr::gather(loc, LocationName, ends_with("stolen_statusLocLocationName"), na.rm = T)
# stolen_statusLocLocationName$loc <- NULL
# stolen_statusLocTrialName = dplyr::select(statuses, ends_with("stolen_statusLocTrialName"))%>%
#   tidyr::gather(loc, TrialName, ends_with("stolen_statusLocTrialName"), na.rm = T)
# stolen_statusLocTrialName$loc <- NULL
# stolen_statusLocTrialYearName = dplyr::select(statuses, ends_with("stolen_statusLocTrialYearName"))%>%
#   tidyr::gather(loc, TrialYearName, ends_with("stolen_statusLocTrialYearName"), na.rm = T)
# stolen_statusLocTrialYearName$loc <- NULL
# stolen_statusLocPlotBlockNumber = dplyr::select(statuses, ends_with("stolen_statusLocPlotBlockNumber"))%>%
#   tidyr::gather(loc, PlotBlockNumber, ends_with("stolen_statusLocPlotBlockNumber"), na.rm = T)
# stolen_statusLocPlotBlockNumber$loc <- NULL
# stolen_statusLocPlotName = dplyr::select(statuses, ends_with("stolen_statusLocPlotName"))%>%
#   tidyr::gather(loc, PlotName, ends_with("stolen_statusLocPlotName"), na.rm = T) 
# stolen_statusLocPlotName$loc <- NULL
# stolen_statusLocPlotRepNumber = dplyr::select(statuses, ends_with("stolen_statusLocPlotRepNumber"))%>%
#   tidyr::gather(loc, PlotRepNumber, ends_with("stolen_statusLocPlotRepNumber"), na.rm = T)
# stolen_statusLocPlotRepNumber$loc <- NULL
# stolen_statusLocPlotColNumber = dplyr::select(statuses, ends_with("stolen_statusLocPlotColNumber"))%>%
#   tidyr::gather(loc, PlotColNumber, ends_with("stolen_statusLocPlotColNumber"), na.rm = T) 
# stolen_statusLocPlotColNumber$loc <- NULL
# stolenLocation = data.frame(cbind(stolen_statusLocAccName, stolen_statusLocLocationName, stolen_statusLocTrialName, 
#                                   stolen_statusLocTrialYearName, stolen_statusLocPlotBlockNumber, stolen_statusLocPlotName,
#                                   stolen_statusLocPlotRepNumber))
# stolen bunch
cross.stolenID = dplyr::select(statuses, ends_with("stolenBunch_statusID"))%>%
  tidyr::gather(cross.status, crossID, ends_with("stolenBunch_statusID"), na.rm = T) %>%
  dplyr::select(crossID) %>%
  tibble::rownames_to_column()

if(nrow(cross.stolenID)>0){
  stolendf = Reduce(function(x,y) merge(x,y,by="rowname"), list(cross.stolenID, stolendate, stolen_notes,stolen_image))
  stolendf$rowname = NULL
  stolendf$status = "Stolen bunch"
} else{
  stolendf = data.frame(cross.stolenID, stolendate, stolen_notes,stolen_image, status = character()) %>%
    dplyr::select(-starts_with("rowname"))
}
colnames(stolendf) = c("ID","date","notes","image", "status")


# Fallen mother
fallen.type = dplyr::select(statuses, ends_with("plant_status")) %>%
  tidyr::gather(type, status, ends_with("plant_status"), na.rm = T) %>%
  filter(status=="fallen")
fallen.type$type = NULL
mother.fallenID = dplyr::select(statuses,ends_with("fallen_statusID"))%>%
  tidyr::gather(mother.status, motherID, ends_with("fallen_statusID"), na.rm = T) %>%
  tibble::rownames_to_column()
mother.fallenID$mother.status <- NULL
fallen_image = dplyr::select(banana, ends_with("fallen_image")) %>%
  tidyr::gather(fallen_image, image, ends_with("fallen_image"), na.rm = T) %>%
  tibble::rownames_to_column()
fallen_image$fallen_image=NULL

if(dim(fallen.type)[1]>0){
  fallendate = dplyr::select(statuses, ends_with("fallen_date")) %>%
    tidyr::gather(date, fallen_date, ends_with("fallen_date"), na.rm = T) %>%
    tibble::rownames_to_column()
  fallendate$date <- NULL
} else {
  fallendate = data.frame(fallen_date=character())
}
fallen_notes = dplyr::select(statuses, ends_with("fallen_comments"))%>%
  tidyr::gather(note, notes, ends_with("fallen_comments"), na.rm = T) %>%
  tibble::rownames_to_column()
fallen_notes$note <- NULL

# fallen_statusLocAccName = dplyr::select(statuses, ends_with("fallen_statusLocAccName"))%>%
#   tidyr::gather(loc, AccessionName, ends_with("fallen_statusLocAccName"), na.rm = T)
# fallen_statusLocAccName$loc <- NULL
# fallen_statusLocLocationName = dplyr::select(statuses, ends_with("fallen_statusLocLocationName"))%>%
#   tidyr::gather(loc, LocationName, ends_with("fallen_statusLocLocationName"), na.rm = T)
# fallen_statusLocLocationName$loc <- NULL
# fallen_statusLocTrialName = dplyr::select(statuses, ends_with("fallen_statusLocTrialName"))%>%
#   tidyr::gather(loc, TrialName, ends_with("fallen_statusLocTrialName"), na.rm = T)
# fallen_statusLocTrialName$loc <- NULL
# fallen_statusLocTrialYearName = dplyr::select(statuses, ends_with("fallen_statusLocTrialYearName"))%>%
#   tidyr::gather(loc, TrialYearName, ends_with("fallen_statusLocTrialYearName"), na.rm = T)
# fallen_statusLocTrialYearName$loc <- NULL
# fallen_statusLocPlotBlockNumber = dplyr::select(statuses, ends_with("fallen_statusLocPlotBlockNumber"))%>%
#   tidyr::gather(loc, PlotBlockNumber, ends_with("fallen_statusLocPlotBlockNumber"), na.rm = T)
# fallen_statusLocPlotBlockNumber$loc <- NULL
# fallen_statusLocPlotName = dplyr::select(statuses, ends_with("fallen_statusLocPlotName"))%>%
#   tidyr::gather(loc, PlotName, ends_with("fallen_statusLocPlotName"), na.rm = T)
# fallen_statusLocPlotName$loc <- NULL
# fallen_statusLocPlotRepNumber = dplyr::select(statuses, ends_with("fallen_statusLocPlotRepNumber"))%>%
#   tidyr::gather(loc, PlotRepNumber, ends_with("fallen_statusLocPlotRepNumber"), na.rm = T)
# fallen_statusLocPlotRepNumber$loc <- NULL
# fallen_statusLocPlotColNumber = dplyr::select(statuses, ends_with("fallen_statusLocPlotColNumber"))%>%
#   tidyr::gather(loc, PlotColNumber, ends_with("fallen_statusLocPlotColNumber"), na.rm = T)
# fallen_statusLocPlotColNumber$loc <- NULL
# fallenLocation = data.frame(cbind(fallen_statusLocAccName, fallen_statusLocLocationName, fallen_statusLocTrialName, 
#                                   fallen_statusLocTrialYearName, fallen_statusLocPlotBlockNumber, fallen_statusLocPlotName,
#                                   fallen_statusLocPlotRepNumber))

if(nrow(mother.fallenID)>0){
mother.fallen.status = Reduce(function(x,y) merge(x,y, by="rowname"),list(mother.fallenID, fallendate, fallen_notes,fallen_image))   %>%
  dplyr::select(-starts_with("rowname"))
mother.fallen.status$status = "Fallen"
} else{
  mother.fallen.status = data.frame(mother.fallenID, fallendate, fallen_notes,fallen_image, status=character())   %>%
    dplyr::select(-starts_with("rowname"))
}
colnames(mother.fallen.status) = c("ID", "date", "notes","image", "status")

# fallen cross
cross.fallenID = dplyr::select(statuses,ends_with("fallenBunch_statusID"))%>%
  tidyr::gather(cross.status, crossID, ends_with("fallenBunch_statusID"), na.rm = T) %>%
  dplyr::select(crossID) %>%
  tibble::rownames_to_column()
  
if(nrow(cross.fallenID)>0){
  cross.fallen.status = Reduce(function(x,y) merge(x,y,by="rowname"), list(cross.fallenID, fallendate, fallen_notes,fallen_image)) %>%
    dplyr::select(-starts_with("rowname"))
  cross.fallen.status$status = "Fallen bunch"
  colnames(cross.fallen.status) = c("ID", "date","notes","image", "status")
  fallendf = rbind(mother.fallen.status, cross.fallen.status)
} else {
  fallendf = mother.fallen.status
}

# Other statuses
# Has disease
diseasetype = dplyr::select(statuses, ends_with("plant_status")) %>%
  tidyr::gather(type, status, ends_with("plant_status"), na.rm = T) %>%
  filter(status=="has_disease") %>% dplyr::select("status")
diseaseID = dplyr::select(statuses,ends_with("plant_diseaseID"))%>%
  tidyr::gather(disease, ID, ends_with("plant_diseaseID"), na.rm = T) %>% 
  dplyr::select("ID") %>%
  tibble::rownames_to_column()

disease_image = dplyr::select(statuses, ends_with("disease_image")) %>%
  tidyr::gather(disease_image, image, ends_with("disease_image"), na.rm = T) %>% 
  dplyr::select("image") %>%
  tibble::rownames_to_column()

if(dim(diseasetype)[1]>0){
  disease.date = dplyr::select(statuses, ends_with("plant_disease_date")) %>%
    tidyr::gather(sdate, date, ends_with("plant_disease_date"), na.rm = T) %>%
    dplyr::select("date") %>%
    tibble::rownames_to_column()
} else {
  disease.date = data.frame(date=character())
}
disease_notes = dplyr::select(statuses, ends_with("disease_comments"))%>%
  tidyr::gather(note, notes, ends_with("disease_comments"), na.rm = T) %>% 
  dplyr::select("notes") %>%
  tibble::rownames_to_column()

# plant_diseaseLocAccName = dplyr::select(statuses, ends_with("plant_diseaseLocAccName"))%>%
#   tidyr::gather(loc, AccessionName, ends_with("plant_diseaseLocAccName"), na.rm = T) %>% 
#   dplyr::select("AccessionName") %>%
#   tibble::rownames_to_column()

# plant_diseaseLocLocationName = dplyr::select(statuses, ends_with("plant_diseaseLocLocationName"))%>%
#   tidyr::gather(loc, LocationName, ends_with("plant_diseaseLocLocationName"), na.rm = T) %>% 
#   dplyr::select("LocationName") %>%
#   tibble::rownames_to_column()
# 
# plant_diseaseLocTrialName = dplyr::select(statuses, ends_with("plant_diseaseLocTrialName"))%>%
#   tidyr::gather(loc, TrialName, ends_with("plant_diseaseLocTrialName"), na.rm = T) %>% 
#   dplyr::select("TrialName") %>%
#   tibble::rownames_to_column()
# 
# plant_diseaseLocTrialYearName = dplyr::select(statuses, ends_with("plant_diseaseLocTrialYearName"))%>%
#   tidyr::gather(loc, TrialYearName, ends_with("plant_diseaseLocTrialYearName"), na.rm = T) %>% 
#   dplyr::select("TrialYearName") %>%
#   tibble::rownames_to_column()
# 
# plant_diseaseLocPlotBlockNumber = dplyr::select(statuses, ends_with("plant_diseaseLocPlotBlockNumber"))%>%
#   tidyr::gather(loc, PlotBlockNumber, ends_with("plant_diseaseLocPlotBlockNumber"), na.rm = T) %>% 
#   dplyr::select("PlotBlockNumber") %>%
#   tibble::rownames_to_column()
# 
# plant_diseaseLocPlotName = dplyr::select(statuses, ends_with("plant_diseaseLocPlotName"))%>%
#   tidyr::gather(loc, PlotName, ends_with("plant_diseaseLocPlotName"), na.rm = T) %>%
#   dplyr::select("PlotName")%>%
#   tibble::rownames_to_column()
# 
# plant_diseaseLocPlotRepNumber = dplyr::select(statuses, ends_with("plant_diseaseLocPlotRepNumber"))%>%
#   tidyr::gather(loc, PlotRepNumber, ends_with("plant_diseaseLocPlotRepNumber"), na.rm = T) %>% 
#   dplyr::select("PlotRepNumber")%>%
#   tibble::rownames_to_column()
# 
# plant_diseaseLocPlotColNumber = dplyr::select(statuses, ends_with("plant_diseaseLocPlotColNumber"))%>%
#   tidyr::gather(loc, PlotColNumber, ends_with("plant_diseaseLocPlotColNumber"), na.rm = T) %>% 
#   dplyr::select("PlotColNumber")%>%
#   tibble::rownames_to_column()

# plant_diseaseLoc = data.frame(cbind(plant_diseaseLocAccName, plant_diseaseLocLocationName, plant_diseaseLocTrialName, 
#                                     plant_diseaseLocTrialYearName, plant_diseaseLocPlotBlockNumber, plant_diseaseLocPlotName,
#                                     plant_diseaseLocPlotRepNumber))

if(nrow(diseaseID)){
diseaseDT = Reduce(function(x,y)merge(x,y,by="rowname"), list(diseaseID, disease.date, disease_notes,disease_image))  %>%
  dplyr::select(-starts_with("rowname"))
diseaseDT$status = "Has a disease"
} else {
  diseaseDT = data.frame(diseaseID, disease.date, disease_notes,disease_image, status=character())  %>%
    dplyr::select(-starts_with("rowname"))
}
diseaseDT = unique(diseaseDT)

# Has died
diedtype = dplyr::select(statuses, ends_with("plant_status")) %>%
  tidyr::gather(type, status, ends_with("plant_status"), na.rm = T) %>%
  filter(status=="died") %>% dplyr::select("status") %>%
  tibble::rownames_to_column()
diedID = dplyr::select(statuses,ends_with("plant_diedID"))%>%
  tidyr::gather(died, ID, ends_with("plant_diedID"), na.rm = T) %>% dplyr::select("ID") %>%
  tibble::rownames_to_column()

died_image = dplyr::select(statuses, ends_with("died_image")) %>%
  tidyr::gather(died_image, image, ends_with("died_image"), na.rm = T) %>% dplyr::select("image") %>%
  tibble::rownames_to_column()
if(dim(diedtype)[1]>0){
  died.date = dplyr::select(statuses, ends_with("plant_died_date")) %>%
    tidyr::gather(sdate, date, ends_with("plant_died_date"), na.rm = T) %>% dplyr::select("date") %>%
    tibble::rownames_to_column()
} else {
  died.date = data.frame(date=character())
}
died_notes = dplyr::select(statuses, ends_with("died_comments"))%>%
  tidyr::gather(note, notes, ends_with("died_comments"), na.rm = T) %>% dplyr::select("notes") %>%
  tibble::rownames_to_column()
# plant_diedLocAccName = dplyr::select(statuses, ends_with("plant_diedLocAccName"))%>%
#   tidyr::gather(loc, AccessionName, ends_with("plant_diedLocAccName"), na.rm = T) %>% dplyr::select("AccessionName") %>%
#   tibble::rownames_to_column()
# 
# plant_diedLocLocationName = dplyr::select(statuses, ends_with("plant_diedLocLocationName"))%>%
#   tidyr::gather(loc, LocationName, ends_with("plant_diedLocLocationName"), na.rm = T) %>% dplyr::select("LocationName")
# 
# plant_diedLocTrialName = dplyr::select(statuses, ends_with("plant_diedLocTrialName"))%>%
#   tidyr::gather(loc, TrialName, ends_with("plant_diedLocTrialName"), na.rm = T) %>% dplyr::select("TrialName")
# 
# plant_diedLocTrialYearName = dplyr::select(statuses, ends_with("plant_diedLocTrialYearName"))%>%
#   tidyr::gather(loc, TrialYearName, ends_with("plant_diedLocTrialYearName"), na.rm = T) %>% dplyr::select("TrialYearName")
# 
# plant_diedLocPlotBlockNumber = dplyr::select(statuses, ends_with("plant_diedLocPlotBlockNumber"))%>%
#   tidyr::gather(loc, PlotBlockNumber, ends_with("plant_diedLocPlotBlockNumber"), na.rm = T) %>% dplyr::select("PlotBlockNumber")
# 
# plant_diedLocPlotName = dplyr::select(statuses, ends_with("plant_diedLocPlotName"))%>%
#   tidyr::gather(loc, PlotName, ends_with("plant_diedLocPlotName"), na.rm = T) %>% dplyr::select("PlotName")
# 
# plant_diedLocPlotRepNumber = dplyr::select(statuses, ends_with("plant_diedLocPlotRepNumber"))%>%
#   tidyr::gather(loc, PlotRepNumber, ends_with("plant_diedLocPlotRepNumber"), na.rm = T) %>% dplyr::select("PlotRepNumber")
# 
# plant_diedLocPlotColNumber = dplyr::select(statuses, ends_with("plant_diedLocPlotColNumber"))%>%
#   tidyr::gather(loc, PlotColNumber, ends_with("plant_diedLocPlotColNumber"), na.rm = T) %>% dplyr::select("PlotColNumber")
# 
# plant_diedLoc = data.frame(cbind(plant_diedLocAccName, plant_diedLocLocationName, plant_diedLocTrialName, 
#                                  plant_diedLocTrialYearName, plant_diedLocPlotBlockNumber, plant_diedLocPlotName,
#                                  plant_diedLocPlotRepNumber))
if(nrow(diedID)>0){
diedDT = Reduce(function(x,y) merge(x,y,by="rowname"),list(diedID, died.date, died_notes,died_image))  %>%
  dplyr::select(-starts_with("rowname"))
diedDT$status = "Plant died"
} else{
  diedDT = data.frame(diedID, died.date, died_notes,died_image, status=character())  %>%
    dplyr::select(-starts_with("rowname"))
}
diedDT = unique(diedDT)

# Has unusual
unusualtype = dplyr::select(statuses, ends_with("plant_status")) %>%
  tidyr::gather(type, status, ends_with("plant_status"), na.rm = T) %>%
  filter(status=="unusual") %>% dplyr::select("status") %>%
  tibble::rownames_to_column()
unusualID = dplyr::select(statuses,ends_with("plant_unusualID"))%>%
  tidyr::gather(unusual, ID, ends_with("plant_unusualID"), na.rm = T) %>% dplyr::select("ID") %>%
  tibble::rownames_to_column()
unusual_image = dplyr::select(statuses, ends_with("unusual_image")) %>%
  tidyr::gather(unusual_image, image, ends_with("unusual_image"), na.rm = T) %>% dplyr::select("image") %>%
  tibble::rownames_to_column()
if(dim(unusualtype)[1]>0){
  unusual.date = dplyr::select(statuses, ends_with("plant_unusual_date")) %>%
    tidyr::gather(sdate, date, ends_with("plant_unusual_date"), na.rm = T) %>% dplyr::select("date") %>%
    tibble::rownames_to_column()
} else {
  unusual.date = data.frame(date=character())
}
unusual_notes = dplyr::select(statuses, ends_with("unusual_comments"))%>%
  tidyr::gather(note, notes, ends_with("unusual_comments"), na.rm = T) %>% dplyr::select("notes") %>%
  tibble::rownames_to_column()
# plant_unusualLocAccName = dplyr::select(statuses, ends_with("plant_unusualLocAccName"))%>%
#   tidyr::gather(loc, AccessionName, ends_with("plant_unusualLocAccName"), na.rm = T) %>% dplyr::select("AccessionName")
# 
# plant_unusualLocLocationName = dplyr::select(statuses, ends_with("plant_unusualLocLocationName"))%>%
#   tidyr::gather(loc, LocationName, ends_with("plant_unusualLocLocationName"), na.rm = T) %>% dplyr::select("LocationName")
# 
# plant_unusualLocTrialName = dplyr::select(statuses, ends_with("plant_unusualLocTrialName"))%>%
#   tidyr::gather(loc, TrialName, ends_with("plant_unusualLocTrialName"), na.rm = T) %>% dplyr::select("TrialName")
# 
# plant_unusualLocTrialYearName = dplyr::select(statuses, ends_with("plant_unusualLocTrialYearName"))%>%
#   tidyr::gather(loc, TrialYearName, ends_with("plant_unusualLocTrialYearName"), na.rm = T) %>% dplyr::select("TrialYearName")
# 
# plant_unusualLocPlotBlockNumber = dplyr::select(statuses, ends_with("plant_unusualLocPlotBlockNumber"))%>%
#   tidyr::gather(loc, PlotBlockNumber, ends_with("plant_unusualLocPlotBlockNumber"), na.rm = T) %>% dplyr::select("PlotBlockNumber")
# 
# plant_unusualLocPlotName = dplyr::select(statuses, ends_with("plant_unusualLocPlotName"))%>%
#   tidyr::gather(loc, PlotName, ends_with("plant_unusualLocPlotName"), na.rm = T) %>% dplyr::select("PlotName")
# 
# plant_unusualLocPlotRepNumber = dplyr::select(statuses, ends_with("plant_unusualLocPlotRepNumber"))%>%
#   tidyr::gather(loc, PlotRepNumber, ends_with("plant_unusualLocPlotRepNumber"), na.rm = T) %>% dplyr::select("PlotRepNumber")
# 
# plant_unusualLocPlotColNumber = dplyr::select(statuses, ends_with("plant_unusualLocPlotColNumber"))%>%
#   tidyr::gather(loc, PlotColNumber, ends_with("plant_unusualLocPlotColNumber"), na.rm = T) %>% dplyr::select("PlotColNumber")
# 
# plant_unusualLoc = data.frame(cbind(plant_unusualLocAccName, plant_unusualLocLocationName, plant_unusualLocTrialName, 
#                                     plant_unusualLocTrialYearName, plant_unusualLocPlotBlockNumber, plant_unusualLocPlotName,
#                                     plant_unusualLocPlotRepNumber))

if(nrow(unusualID)>0){
unusualDT = Reduce(function(x,y) merge(x,y,by="rowname"),list(unusualID, unusual.date, unusual_notes,unusual_image))  %>%
  dplyr::select(-starts_with("rowname"))
unusualDT$status = "unusual"
} else{
  unusualDT = data.frame(unusualID, unusual.date, unusual_notes,unusual_image, status=character())  %>%
    dplyr::select(-starts_with("rowname"))
}

# Has destroyed
destroyedtype = dplyr::select(statuses, ends_with("plant_status")) %>%
  tidyr::gather(type, status, ends_with("plant_status"), na.rm = T) %>%
  filter(status=="destroyed") %>% dplyr::select("status") %>%
  tibble::rownames_to_column()
destroyedID = dplyr::select(statuses,ends_with("plant_destroyedID"))%>%
  tidyr::gather(destroyed, ID, ends_with("plant_destroyedID"), na.rm = T) %>% dplyr::select("ID") %>%
  tibble::rownames_to_column()

destroyed_image = dplyr::select(statuses, ends_with("destroyed_image")) %>%
  tidyr::gather(destroyed_image, image, ends_with("destroyed_image"), na.rm = T) %>% dplyr::select("image") %>%
  tibble::rownames_to_column()
if(dim(destroyedtype)[1]>0){
  destroyed.date = dplyr::select(statuses, ends_with("plant_destroyed_date")) %>%
    tidyr::gather(sdate, date, ends_with("plant_destroyed_date"), na.rm = T) %>% dplyr::select("date") %>%
    tibble::rownames_to_column()
} else {
  destroyed.date = data.frame(date=character())
}
destroyed_notes = dplyr::select(statuses, ends_with("destroyed_comments"))%>%
  tidyr::gather(note, notes, ends_with("destroyed_comments"), na.rm = T) %>% dplyr::select("notes") %>%
  tibble::rownames_to_column()
# plant_destroyedLocAccName = dplyr::select(statuses, ends_with("plant_destroyedLocAccName"))%>%
#   tidyr::gather(loc, AccessionName, ends_with("plant_destroyedLocAccName"), na.rm = T) %>% dplyr::select("AccessionName")
# 
# plant_destroyedLocLocationName = dplyr::select(statuses, ends_with("plant_destroyedLocLocationName"))%>%
#   tidyr::gather(loc, LocationName, ends_with("plant_destroyedLocLocationName"), na.rm = T) %>% dplyr::select("LocationName")
# 
# plant_destroyedLocTrialName = dplyr::select(statuses, ends_with("plant_destroyedLocTrialName"))%>%
#   tidyr::gather(loc, TrialName, ends_with("plant_destroyedLocTrialName"), na.rm = T) %>% dplyr::select("TrialName")
# 
# plant_destroyedLocTrialYearName = dplyr::select(statuses, ends_with("plant_destroyedLocTrialYearName"))%>%
#   tidyr::gather(loc, TrialYearName, ends_with("plant_destroyedLocTrialYearName"), na.rm = T) %>% dplyr::select("TrialYearName")
# 
# plant_destroyedLocPlotBlockNumber = dplyr::select(statuses, ends_with("plant_destroyedLocPlotBlockNumber"))%>%
#   tidyr::gather(loc, PlotBlockNumber, ends_with("plant_destroyedLocPlotBlockNumber"), na.rm = T) %>% dplyr::select("PlotBlockNumber")
# 
# plant_destroyedLocPlotName = dplyr::select(statuses, ends_with("plant_destroyedLocPlotName"))%>%
#   tidyr::gather(loc, PlotName, ends_with("plant_destroyedLocPlotName"), na.rm = T) %>% dplyr::select("PlotName")
# 
# plant_destroyedLocPlotRepNumber = dplyr::select(statuses, ends_with("plant_destroyedLocPlotRepNumber"))%>%
#   tidyr::gather(loc, PlotRepNumber, ends_with("plant_destroyedLocPlotRepNumber"), na.rm = T) %>% dplyr::select("PlotRepNumber")
# 
# plant_destroyedLocPlotColNumber = dplyr::select(statuses, ends_with("plant_destroyedLocPlotColNumber"))%>%
#   tidyr::gather(loc, PlotColNumber, ends_with("plant_destroyedLocPlotColNumber"), na.rm = T) %>% dplyr::select("PlotColNumber")
# 
# plant_destroyedLoc = data.frame(cbind(plant_destroyedLocAccName, plant_destroyedLocLocationName, plant_destroyedLocTrialName, 
#                                       plant_destroyedLocTrialYearName, plant_destroyedLocPlotBlockNumber, plant_destroyedLocPlotName,
#                                       plant_destroyedLocPlotRepNumber))

if(nrow(destroyedID)>0){
  destroyedDT = Reduce(function(x,y) merge(x,y, by="rowname"), list(destroyedID, destroyed.date, destroyed_notes,destroyed_image))  %>%
    dplyr::select(-starts_with("rowname"))
  destroyedDT$Status = "Destroyed"
}else{
  destroyedDT = data.frame(destroyedID, destroyed.date, destroyed_notes,destroyed_image)  %>%
    dplyr::select(-starts_with("rowname"))
}
destroyedDT = unique(destroyedDT)


# -------- screenhouse status
sstatus = dplyr::select(banana, contains("screenhse_status"))
sstatusDate = dplyr::select(sstatus, ends_with("scrnhsestatus_Date"))%>%
  tidyr::gather(sdate,date, ends_with("scrnhsestatus_Date"), na.rm = T) %>% dplyr::select(date) %>%
  tibble::rownames_to_column()
sstatusID = dplyr::select(sstatus, ends_with("scrnhse_statusID"))%>%
  tidyr::gather(ssID, ID, ends_with("scrnhse_statusID"), na.rm = T) %>% dplyr::select(ID) %>%
  tibble::rownames_to_column()
s.status = dplyr::select(sstatus, ends_with("scrnhseStatus"))%>%
  tidyr::gather(sstatus, status, ends_with("scrnhseStatus"), na.rm = T) %>% dplyr::select(status) %>%
  tibble::rownames_to_column()
simage = dplyr::select(sstatus, ends_with("status_image_scrnhse")) %>%
  tidyr::gather(img, image, ends_with("status_image_scrnhse"), na.rm = T) %>% dplyr::select(image) %>%
  tibble::rownames_to_column()

ssnotes = dplyr::select(sstatus, ends_with("note_scrnhse_status")) %>%
  tidyr::gather(note, notes, ends_with("note_scrnhse_status"), na.rm = T) %>% dplyr::select(notes) %>%
  tibble::rownames_to_column()

screenhseStatus = Reduce(function(x,y) merge(x,y, by="rowname"), list(sstatusID, sstatusDate, s.status, ssnotes, simage)) %>%
  dplyr::select(-rowname)


# ---------------
statusDF = rbind(fallendf, diseaseDT, unusualDT, diedDT, destroyedDT,screenhseStatus)
statusDF$statusID = statusDF$ID
statusDF$date = as.Date(statusDF$date)
if(nrow(statusDF)>0){
statusDF$location = "Arusha"
} else { status$location = character()}
#-----------------------------------------------------------------------------------------------------------------------------------------
write.csv(statusDF, file = "ArushaStatus.csv", row.names = F)
saveRDS(statusDF, file = "ArushaStatus.rds")

#------------------------------------------------------------------------------------------------------------------------------------------
# Contamination
ContaminID <- dplyr::select(banana,ends_with("econtaminationID")) %>%
  tidyr::gather(contamination, crossnumber, ends_with("econtaminationID"), na.rm = T)
contaminationID <- data.frame(ContaminID$crossnumber)
ContaminDate <- dplyr::select(banana, ends_with("contamination_date")) %>%
  tidyr::gather(date, contamination_date, ends_with("contamination_date"), na.rm = T)
contaminated = dplyr::select(banana, ends_with("contaminated")) %>%
  tidyr::gather(contamination, contaminated, ends_with("contaminated"), na.rm=T)

contamination <- as.data.frame(c(ContaminID, contaminationID, ContaminDate, contaminated)) %>%
  dplyr::select(crossnumber,ContaminID.crossnumber, contamination_date, contaminated)
colnames(contamination) <- c("crossnumber","contaminationID","contamination_date","contamination")
contamination$time <- NULL
if(nrow(contamination)>0){
contamination$location = "Arusha"
} else {contamination$location = character() }
write.csv(contamination, file = "ArushaContamination.csv", row.names = F)
saveRDS(contamination, file = "ArushaContamination.rds")

# POST MEDIA FILES TO ONA
# Get tokens
raw.result <- GET("https://api.ona.io/api/v1/user.json", authenticate(user = "*****",password = "******"))
raw.result.char<-rawToChar(raw.result$content)
raw.result.json<-fromJSON(raw.result.char)
TOKEN_KEY <- raw.result.json$temp_token

#----------------------------------------------------------------------------------------------------------------------------------------------
# flowering
meta_flowerid <- readChar("arusha_flowerid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_flowerid),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# post
new_flower_id <- ''
while(new_flower_id == ''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.flower.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='ArushaFlowering.csv',data_type='media',xform=286910,
                                  data_file=fileUpload(filename = "ArushaFlowering.csv",contentType = 'text/csv'),
                                  .opts=list(httpheader=header), verbose = TRUE)
  
  # flowerID
  flower.raw.result.json<-fromJSON(post.flower.results)
  new_flower_id <- flower.raw.result.json$id
}
meta_flower <- cat(new_flower_id, file = "arusha_flowerid.txt")

#----------------------------------------------------------------------------------------------------------------------------------------------
# seeds germinating after 8 weeks
meta_germ_8weeks <- readChar("arusha_germ_8weeks.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_germ_8weeks),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

new_seeds_id <- ''
while(new_seeds_id ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.germ_8weeks.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                       data_value='ArushaSeedsGerminatingAfter8Weeks.csv',data_type='media',xform=286910,
                                       data_file=fileUpload(filename = "ArushaSeedsGerminatingAfter8Weeks.csv",contentType = 'text/csv'),
                                       .opts=list(httpheader=header), verbose = TRUE)
  
  # germinating after 8 weeks
  germ_8weeks.raw.result.json<-fromJSON(post.germ_8weeks.results)
  new_seeds_id <- germ_8weeks.raw.result.json$id
  
}
cat(new_seeds_id, file = "arusha_germ_8weeks.txt")
#----------------------------------------------------------------------------------------------------------------------------------------------
# bananadata
meta_bananaid <- readChar("arusha_bananaid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_bananaid),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload bananadata
new_banana_id <- ''
while(new_banana_id==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.banana.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='ArushaBananaData.csv',data_type='media',xform=286910,
                                  data_file=fileUpload(filename = "ArushaBananaData.csv",contentType = 'text/csv'),
                                  
                                  .opts=list(httpheader=header), verbose = TRUE)
  # Bananadata ID
  banana.raw.result.json<-fromJSON(post.banana.results)
  new_banana_id <- banana.raw.result.json$id
}
cat(new_banana_id, file = "arusha_bananaid.txt")

#----------------------------------------------------------------------------------------------------------------------------------------------
# Status	
meta_statusID <- readChar("arusha_statusID.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_statusID),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# status upload
new_status_id <- ''
while(new_status_id ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.status.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='ArushaStatus.csv',data_type='media',xform=286910,
                                  data_file=fileUpload(filename = "ArushaStatus.csv",contentType = 'text/csv'),
                                  .opts=list(httpheader=header), verbose = TRUE)
  # get status ID
  status.raw.result.json<-fromJSON(post.status.results)
  new_status_id <- status.raw.result.json$id
}
cat(new_status_id, file = "arusha_statusID.txt")

#----------------------------------------------------------------------------------------------------------------------------------------------
# Contamination
meta_contaminationID <- readChar("arusha_contaminationID.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_contaminationID),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# contamination upload
new_contamination_id <- ''
while(new_contamination_id==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.contamination.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                         data_value='ArushaContamination.csv',data_type='media',xform=286910,
                                         data_file=fileUpload(filename = "ArushaContamination.csv",contentType = 'text/csv'),
                                         .opts=list(httpheader=header), verbose = TRUE)
  
  # get contamination ID
  contamination.raw.result.json<-fromJSON(post.contamination.results)
  new_contamination_id <- contamination.raw.result.json$id
}
cat(new_contamination_id, file = "arusha_contaminationID.txt")

#----------------------------------------------------------------------------------------------------------------------------------------------
# Plantlets
meta_plantletsID = readChar("arusha_plantletsID.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_plantletsID),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# Plantlets upload
new_plantlets_id <- ''
while(new_plantlets_id ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.plantlets.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                     data_value='ArushaPlantlets.csv',data_type='media',xform=286910,
                                     data_file=fileUpload(filename = "ArushaPlantlets.csv",contentType = 'text/csv'),
                                     .opts=list(httpheader=header), verbose = TRUE)
  # get plantlets ID
  plantlets.raw.result.json<-fromJSON(post.plantlets.results)
  new_plantlets_id <- plantlets.raw.result.json$id
}
cat(new_plantlets_id, file = "arusha_plantletsID.txt")


#----------------------------------------------------------------------------------------------------------------------------------------------
# crosses per female plot
meta_ncrosses = readChar("arusha_ncrosses.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",meta_ncrosses),add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
new_ncrosses <- ''
while(new_ncrosses ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), `Content-Type` = 'multipart/form-data')
  post.ncrosses.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                     data_value='ArushaCrossesPerFemalePlot.csv',data_type='media',xform=286910,
                                     data_file=fileUpload(filename = "ArushaCrossesPerFemalePlot.csv",contentType = 'text/csv'),
                                     .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  ncrosses.raw.result.json<-fromJSON(post.ncrosses.results)
  new_ncrosses <- ncrosses.raw.result.json$id
}
cat(new_ncrosses, file = "arusha_ncrosses.txt")


