
rm(list=ls(all=T))
cat("\014")
library(dplyr)
library(lubridate)
library(mailR)

#source("/srv/shiny-server/btract/btract/loaddata.R")

library(magrittr)
library(data.table)
library(dplyr)
setwd("/srv/shiny-server/btract/btract")
# Load data 
flowering = list.files(patt="AllFlowering.csv$", recursive = TRUE) %>%
  lapply(fread) %>%
  rbindlist(id=T, fill=T) %>%
  .[,-1]
flowering$Location = as.factor(flowering$Location)
flowering$Accession_Name = as.factor(flowering$Accession_Name)
flowering$Plant_Sex = as.factor(flowering$Plant_Sex)
flowering$Flowering_Date = anytime::anydate(as.character(flowering$Flowering_Date))
colnames(flowering) = gsub("_"," ", names(flowering))

seeds_data = list.files(patt="SeedsGerminatingAfter8Weeks.csv$", recursive = TRUE) %>%
  lapply(fread) %>%
  rbindlist(id=T, fill=T) %>%
  .[,-1]
seeds_data = seeds_data[complete.cases(seeds_data),]
seeds_data$Location = as.factor(seeds_data$Location)
if(nrow(seeds_data)>0){
  seeds_data$Germination_after_8_Weeks_Date = anytime::anydate(seeds_data$Germination_after_8_Weeks_Date)
} else {
  seeds_data$Germination_after_8_Weeks_Date = anytime::anydate(as.character(seeds_data$`Germination after 8 Weeks Date`))
}
colnames(seeds_data) = gsub("_"," ",names(seeds_data))

status = list.files(patt="Status.csv$", recursive = TRUE) %>% # add location in script
  lapply(fread) %>%
  rbindlist(id=T, fill=T) %>% .[,-1] 

status$Status_Date = anytime::anydate(as.character(status$Status_Date))
colnames(status) = gsub("_"," ", names(status))
status$Image = paste0("<a href='",status$Image,"'>",'photo',"</a>")
status = dplyr::select(status, Location, StatusID, `Status Date`,Status, everything())

contamination = list.files(patt="Contamination.csv$", recursive = TRUE) %>%
  lapply(fread) %>%
  rbindlist(id=T, fill=T) %>% .[,-1]

contamination$Location = as.factor(contamination$Location)
contamination$Contamination_Date = anytime::anydate(as.character(contamination$Contamination_Date))
colnames(contamination) = gsub("_"," ", names(contamination))

plantlets = list.files(patt="Plantlets.csv$", recursive = TRUE) %>%
  lapply(fread) %>%
  rbindlist(id=T, fill = T)
plantlets = plantlets[,-1]

plantlets$Subculture_Date = anytime::anydate(as.character(plantlets$Subculture_Date))
plantlets$Date_of_Rooting = anytime::anydate(as.character(plantlets$Date_of_Rooting))
plantlets$Location = as.factor(plantlets$Location)
plantlets$Screenhouse_Transfer_Date = anytime::anydate(as.character(plantlets$Screenhouse_Transfer_Date))
plantlets$Hardening_Date = anytime::anydate(as.character(plantlets$Hardening_Date))
plantlets$Openfield_Transfer_Date = anytime::anydate(as.character(plantlets$Openfield_Transfer_Date))
plantlets = plantlets %>% dplyr::select(Location, PlantletID, -c("SeedID"), everything())
colnames(plantlets) = gsub("_"," ", names(plantlets))

if(nrow(plantlets)>0){
  
  plantlets$Crossnumber = ifelse(bananadata$Crossnumber==substr(plantlets$PlantletID, 1, nchar(bananadata$Crossnumber)), bananadata$Crossnumber,"")
  plantlets = Reduce(function(x,y) merge(x,y, by="Crossnumber"), list(bananadata[,c("Crossnumber","Mother","Father")], plantlets))
}

crosses = list.files(patt="BananaData.csv$", recursive = TRUE) %>%
  lapply(fread) %>%
  rbindlist(id=T, fill = T) %>% .[,-1]
##******************************************************
crosses = setDT(crosses)[crosses[, .I[which.min(Reduce(`+`, lapply(.SD, is.na)))], Crossnumber]$V1]
crosses$First_Pollination_Date = anytime::anydate(as.character(crosses$First_Pollination_Date))
# previous records
arusha_legacy_crosses = fread("data/Last_6_months_tisssue_culture_data.csv")
rmcol = c("contamination","badseeds",grep("^days", names(arusha_legacy_crosses), value = T))
arusha_legacy_crosses = arusha_legacy_crosses[, (rmcol) := NULL][] %>% # drop unwanted columns
  setnames(colnames(.), c("Location","Crossnumber","Mother","Father","First_Pollination_Date","Bunch_Harvest_Date", "Seed_Extraction_Date",
                          "Total_Seeds","Good_Seeds","Number_of_Embryo_Rescued", "Embryo_Rescue_Date", "Germination_after_8_Weeks_Date",                  
                          "Active_after_8_Weeks"))
arusha_legacy_crosses$First_Pollination_Date = anytime::anydate(as.character(arusha_legacy_crosses$First_Pollination_Date))

# merge crosses and previous datasets
banana = plyr::rbind.fill(crosses, arusha_legacy_crosses)
#banana = rbindlist(sets, use.names = T,fill=T,idcol = NULL)
banana$First_Pollination_Date = anytime::anydate(as.character(banana$First_Pollination_Date))

banana$Bunch_Harvest_Date = anytime::anydate(as.character(banana$Bunch_Harvest_Date))
banana$Seed_Extraction_Date = anytime::anydate(as.character(banana$Seed_Extraction_Date))
banana$Embryo_Rescue_Date = anytime::anydate(as.character(banana$Embryo_Rescue_Date))
banana$Germination_after_2_Weeks_Date = anytime::anydate(as.character(banana$Germination_after_2_Weeks_Date))
banana$Germination_after_8_Weeks_Date = anytime::anydate(as.character(banana$Germination_after_8_Weeks_Date))

banana$Days_to_Maturity = as.integer(banana$Bunch_Harvest_Date - banana$First_Pollination_Date)
banana$Days_in_ripening_shed = as.integer(banana$Seed_Extraction_Date - banana$Bunch_Harvest_Date)


# repeat pollination 
repeatpollination = list.files(patt="RepeatPollination.csv$", recursive = TRUE) %>%
  lapply(fread) %>%
  rbindlist(id=T, fill=T) %>%
  .[,-c(1,4)]

repeatDT = as.data.frame(repeatpollination[,number := 1:.N, by = Crossnumber])
repeatDTwide = reshape(repeatDT,direction = "wide", idvar = "Crossnumber", timevar = "number")

repeatDTwide[,2:ncol(repeatDTwide)] = lapply(repeatDTwide[,2:ncol(repeatDTwide)],anytime::anydate)
repeats = setDT(repeatDTwide)[, Number_of_repeat_pollinations := rowSums(!is.na(repeatDTwide))-1][]
bananadt = dplyr::left_join(banana, repeats, by="Crossnumber")
bananadt$Number_of_repeat_pollinations = as.integer(bananadt$Number_of_repeat_pollinations)

# select ID reported with status
bananadt$StatusID = bananadt$Crossnumber
lostInfo = dplyr::inner_join(bananadt, status, by=c("Location","StatusID"))
lostInfo = janitor::remove_empty(lostInfo,"cols")
cols.num <- grep("_Date", names(lostInfo), value = T)
lostInfo[cols.num] <- sapply(lostInfo[cols.num],as.character)

lostInfo = lostInfo %>% tidyr::gather(Last_activity_recorded, Activity_Date, contains("_Date"), na.rm=T)

lostInfo = setDT(lostInfo)[,c("Location","Crossnumber","Last_activity_recorded","Activity_Date","Status","Notes","Image")][order(-Activity_Date)]
lostInfo = lostInfo %>%
  dplyr::filter(Last_activity_recorded !="Status_Date" & Activity_Date !="")

lostInfo$Last_activity_recorded = gsub("_Date","", lostInfo$Last_activity_recorded)
lostInfo$Last_activity_recorded = gsub("_"," ", lostInfo$Last_activity_recorded)

lostInfo$Last_activity_recorded = ifelse(grepl("^Repeat Pollination.", lostInfo$Last_activity_recorded, perl = T)==TRUE,"Repeat Pollination",lostInfo$Last_activity_recorded)
lostInfo = lostInfo[!duplicated(lostInfo$Crossnumber), ]
colnames(lostInfo) = gsub("_"," ", names(lostInfo))

status$Location = as.factor(status$Location)

# drop IDs reported with status
bananadata = dplyr::anti_join(bananadt, status, by="StatusID")
bananadata$StatusID = NULL

###################################
bananadata$Mother = stringr::str_trim(bananadata$Mother, side = "both")
bananadata$Father = stringr::str_trim(bananadata$Father, side = "both")
bananadata$Father = gsub(" - ","-",bananadata$Father)

bananadata$Mother = ifelse(bananadata$Mother %in% c("cv-Rose","ITC0712"),"ITC0712 Cv Rose", bananadata$Mother)
bananadata$Mother = ifelse(bananadata$Mother %in% c("ITC0609","Pahang","Pisang Pahang"),"ITC0609 Pahang", bananadata$Mother)
bananadata$Mother = ifelse(bananadata$Mother %in% c("Calcutta 4","ITC0249"),"ITC0249 Calcutta 4", bananadata$Mother)
bananadata$Mother = ifelse(bananadata$Mother %in% c("Borneo","ITC0253"),"ITC0253 Borneo", bananadata$Mother)
bananadata$Mother = ifelse(bananadata$Mother %in% c("ITC0766","Paliama"),"ITC0766 Paliama", bananadata$Mother)
bananadata$Mother = ifelse(bananadata$Mother %in% c("ITC1460","Ijihu nkundu"),"ITC1460-Ijihu nkundu", bananadata$Mother)
bananadata$Mother = ifelse(bananadata$Mother %in% c("ITC1468","Kahuti"),"ITC1468-Kahuti", bananadata$Mother)

bananadata$Father = ifelse(bananadata$Father %in% c("cv-Rose","ITC0712"),"ITC0712 Cv Rose", bananadata$Father)
bananadata$Father = ifelse(bananadata$Father %in% c("ITC0609","Pahang","Pisang Pahang"),"ITC0609 Pahang", bananadata$Father)
bananadata$Father = ifelse(bananadata$Father %in% c("Calcutta 4","ITC0249"),"ITC0249 Calcutta 4", bananadata$Father)
bananadata$Father = ifelse(bananadata$Father %in% c("Borneo","ITC0253"),"ITC0253 Borneo", bananadata$Father)
bananadata$Father = ifelse(bananadata$Father %in% c("ITC0766","Paliama"),"ITC0766 Paliama", bananadata$Father)
bananadata$Father = ifelse(bananadata$Father %in% c("ITC1460","Ijihu nkundu"),"ITC1460-Ijihu nkundu", bananadata$Father)
bananadata$Father = ifelse(bananadata$Father %in% c("ITC1468","Kahuti"),"ITC1468-Kahuti", bananadata$Father)

# library(brapi)
# mb = brapi::ba_db()$musabase
# accessions = brapi::ba_germplasm_search(mb, rclass="data.frame") %>%
#   dplyr::select(germplasmName,synonyms)
# 
# bananadata$Mother = ifelse(bananadata$Mother %in% accessions$synonyms, accessions$germplasmName, bananadata$Mother)
# bananadata$Father = ifelse(bananadata$Father %in% accessions$synonyms, accessions$germplasmName, bananadata$Father)

#######################################
bananadata = bananadata %>%
  dplyr::select(Location, Crossnumber, FemalePlotName, Mother, MalePlotName, Father, First_Pollination_Date, Number_of_repeat_pollinations,
                Days_to_Maturity,Bunch_Harvest_Date, Days_in_ripening_shed, everything(), -c(Cycle,starts_with("Repeat_Pollination_Date.")))

bananadata$Location = as.factor(bananadata$Location)
bananadata$Mother = as.factor(bananadata$Mother)
bananadata$Father = as.factor(bananadata$Father)

# if duplicate germplasm names, keep rows with minimum missing
bananadata = setDT(bananadata)[bananadata[, .I[which.min(Reduce(`+`, lapply(.SD, is.na)))], Crossnumber]$V1]
colnames(bananadata) = gsub("_"," ", names(bananadata))

data.table::fwrite(banana, file="www/documentation/bananadata.csv", row.names = F)
data.table::fwrite(banana, file="bananadata.csv", row.names = F)

##########################################################################################
## DATA EXPLORER
##########################################################################################


if (nrow(flowering)>0){
  flowered = flowering[,c("Location","Accession Name","Flowering Date")]
  flowered$Activity = "Flowering"
  colnames(flowered) <- c("Location","Accession","Date","Activity")
  flowered = flowered[complete.cases(flowered),]
} else {
  flowered = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
}


# F.Polln
if(nrow(bananadata)>0){
  first_pollinationed = bananadata[,c("Location", "Crossnumber", "Mother","Father","First Pollination Date")]
  colnames(first_pollinationed) = c("Location","Accession","Mother","Father","Date")
  first_pollinationed$Activity = "First pollination"
  first_pollinationed = first_pollinationed[complete.cases(first_pollinationed),]
} else {
  first_pollinationed = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
}   

# Repeat Polln
if(nrow(repeatpollination)>0){
  repeat_pollinationed = repeatpollination[,-3] %>%
    dplyr::arrange(.,Crossnumber,desc(Repeat_Pollination_Date)) 
  repeat_pollinationed = repeat_pollinationed[!duplicated(repeat_pollinationed$Crossnumber),]
  repeat_pollinationed = dplyr::left_join(repeat_pollinationed, bananadata[,c("Location","Crossnumber","Mother","Father")], by="Crossnumber")
  colnames(repeat_pollinationed) = c("Accession","Date","Location","Mother","Father")
  repeat_pollinationed$Date = anytime::anydate(repeat_pollinationed$Date)
  repeat_pollinationed $Activity = "Repeat pollination"
}

# Harvest
harvested = bananadata[,c("Location", "Crossnumber", "Mother","Father","Bunch Harvest Date")]
colnames(harvested) = c("Location","Accession","Mother","Father","Date")
if(nrow(harvested)>0){
  harvested$Activity = "Harvested bunches"
}
harvested = harvested[complete.cases(harvested),]

# Extracted
extracted = bananadata[, c("Location","Crossnumber","Mother","Father","Seed Extraction Date")]
colnames(extracted) <- c("Location","Accession","Mother","Father","Date")
if(nrow(extracted)>0){
  extracted$Activity = "Seed extraction"
}
extracted = extracted[complete.cases(extracted),]

# Rescue
rescued = bananadata[,c("Location","Crossnumber","Mother","Father","Embryo Rescue Date")]
colnames(rescued) <- c("Location","Accession","Mother","Father","Date")
if(nrow(rescued)>0){
  rescued$Activity = "Embryo Rescue"
}
#rescued$Date = lubridate::dmy(rescued$Date)
rescued = rescued[complete.cases(rescued),]

# Germinated after 2wks
germinated_2weeks = bananadata[,c("Location","Crossnumber","Mother","Father","Germination after 2 Weeks Date")]
colnames(germinated_2weeks) <- c("Location","Accession","Mother","Father","Date")
if(nrow(germinated_2weeks)>0){
  germinated_2weeks$Activity = "Germination after 2 weeks"
}
#germinated_2weeks$Date = anytime::anydate(as.character(germinated_2weeks$Date))
germinated_2weeks = germinated_2weeks[complete.cases(germinated_2weeks),]

# Germinated after 8weeks
germinated_8weeks = bananadata[,c("Location","Crossnumber","Mother","Father","Germination after 8 Weeks Date")]
colnames(germinated_8weeks) <- c("Location","Accession","Mother","Father","Date")
if(nrow(germinated_8weeks)>0){
  germinated_8weeks$Activity = "Germination after 8 weeks"
}
germinated_8weeks = germinated_8weeks[complete.cases(germinated_8weeks),]
#} # end if

# Seeds germinating after 8weeks
#if(nrow(seeds_data)>0){
germinating_seeds = seeds_data
germinating_seeds$Activity = "Seeds germinating after 8 weeks"
germinating_seeds = germinating_seeds[complete.cases(germinating_seeds),]
# }

# Subculture
if(nrow(plantlets)>0){
  subcul = plantlets[,c("Location","PlantletID","Mother","Father","Subculture Date")]
  colnames(subcul) <- c("Location","Accession","Mother","Father","Date")
  subcul$Date = anytime::anydate(as.character(subcul$Date))
  if(nrow(subcul)>0){
    subcul$Activity = "Sub-culturing"
  }
  subcul = subcul[complete.cases(subcul),]
} else{
  subcul = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
}   
# # Rooted
if(nrow(plantlets)>0){   
  rooted = plantlets[,c("Location","PlantletID","Mother","Father","Date of Rooting")]
  colnames(rooted) <- c("Location","Accession","Mother","Father","Date")
  if(nrow(rooted)>0){
    rooted$Activity = "Rooting"
  }
  rooted = rooted[complete.cases(rooted),]
} else{
  rooted = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
}    
# Screenhse
if(nrow(plantlets)>0){      
  screen_housed = plantlets[,c("Location","PlantletID","Mother","Father","Screenhouse Transfer Date")]
  colnames(screen_housed) <- c("Location","Accession","Mother","Father","Date")
  if(nrow(screen_housed)>0){
    screen_housed$Activity = "Screen house"
  }
  screen_housed = screen_housed[complete.cases(screen_housed),]
} else {
  screen_housed = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
}    
# Hardened
if(nrow(plantlets)>0){    
  hardened = plantlets[,c("Location","PlantletID","Mother","Father","Hardening Date")]
  colnames(hardened) <- c("Location","Accession","Mother","Father","Date")
  if(nrow(hardened)>0){
    hardened$Activity = "Hardening"
  }
  hardened = hardened[complete.cases(hardened),]
} else {
  hardened = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
}    
# Openfield
if(nrow(plantlets)>0){    
  open_field = plantlets[,c("Location","PlantletID","Mother","Father","Openfield Transfer Date")]
  colnames(open_field) <- c("Location","Accession","Mother","Father","Date")
  if(nrow(open_field)>0){
    open_field$Activity = "Open field"
  }
  open_field = open_field[complete.cases(open_field),]
} else {
  open_field = data.frame(Location = character(), Accession = character(),Mother = character(),Father = character(),anytime::anydate(integer(0)))
} 

cleantable = plyr::rbind.fill(flowered,first_pollinationed,repeat_pollinationed,
                              harvested,extracted,rescued,germinated_2weeks,germinated_8weeks)



# Monthly reports
reports = cleantable %>%
  dplyr::filter(lubridate::month(Date)==lubridate::month(Sys.Date()-1) &  lubridate::year(as.Date(Date))==lubridate::year(Sys.Date()-1)) %>%
  dplyr::group_by(Location, Activity) %>%
  dplyr::tally() %>%
  dplyr::collect()

loc = unique(reports$Location)
for(k in 1:length(loc)){
  fname <- paste0("Reports/Monthly/BTracT Monthly Report - ",loc[k]," ", month.abb[lubridate::month(Sys.Date()-1)],"-",lubridate::year(Sys.Date()-1),".xls")
  loc_rpt = reports %>%
    dplyr::filter(Location==loc[k])
  colnames(loc_rpt)[3] = "Number reported"
  WriteXLS::WriteXLS(loc_rpt, fname)
}

# --------- email
send.mail(from = "bananatrackertool@gmail.com",
            to = "*****@**.com", 
            subject = paste("BTracT Monthly Report - Arusha ", month.abb[lubridate::month(Sys.Date()-1)],"-",lubridate::year(Sys.Date()-1)),
            body = paste("Attached is the Arusha monthly report for ", month.abb[lubridate::month(Sys.Date()-1)],"-",lubridate::year(Sys.Date()-1)), 
            smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "***@gmail.com", passwd = "1234", ssl = TRUE),
            authenticate = TRUE,
            send = TRUE,
            attach.files = paste0("/srv/shiny-server/btract/btract/Reports/Monthly/BTracT Monthly Report - Arusha ", month.abb[lubridate::month(Sys.Date()-1)],"-",lubridate::year(Sys.Date()-1),".xls"),debug = F)

