suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(httpuv))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(RCurl))

setwd("/home/mwk66/BTRACT/daily/data")

# POST MEDIA FILES TO ONA

# Get tokens

raw.result <- GET("https://api.ona.io/api/v1/user.json", 
                  authenticate(user = "seedtracker",
                               password = "Seedtracking101")
)
raw.result.char<-rawToChar(raw.result$content)
raw.result.json<-fromJSON(raw.result.char)
TOKEN_KEY <- raw.result.json$temp_token


# +++++++++++++++++++++++ NELSON MANDELA ++++++++++++++++++++++++++++++++++++++

# 1a. flowering

flowerid1 <- readChar("nm_flowerid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",flowerid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# post
flower_id1 <- ''
while(flower_id1 == ''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), 
           `Content-Type` = 'multipart/form-data')
  post.flower.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='ArushaFlowering.csv',
                                  data_type='media',
                                  xform=286910,
                                  data_file=fileUpload(filename = "ArushaFlowering.csv",contentType = 'text/csv'),
                                  .opts=list(httpheader=header), verbose = TRUE)
  
  # ID
  flower.raw.result.json<-fromJSON(post.flower.results)
  flower_id1 <- flower.raw.result.json$id
}
cat(flower_id1, file = "nm_flowerid.txt")


# 1b. banana

bananaid1 <- readChar("nm_bananaid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",bananaid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# post 
banana_id1 <- ''
while(banana_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), 
           `Content-Type` = 'multipart/form-data')
  post.banana.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='ArushaBananaData.csv',
                                  data_type='media',xform=286910,
                                  data_file=fileUpload(filename = "ArushaBananaData.csv",contentType = 'text/csv'),
                                  .opts=list(httpheader=header), verbose = TRUE)
  # ID
  banana.raw.result.json<-fromJSON(post.banana.results)
  banana_id1 <- banana.raw.result.json$id
}
cat(banana_id1, file = "nm_bananaid.txt")


# 1c. Plantlets

plantletid1 = readChar("nm_plantletid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",plantletid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
plantlet_id1 <- ''
while(plantlet_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), 
           `Content-Type` = 'multipart/form-data')
  post.plantlets.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                     data_value='ArushaPlantlets.csv',
                                     data_type='media',xform=286910,
                                     data_file=fileUpload(filename = "ArushaPlantlets.csv",contentType = 'text/csv'),
                                     .opts=list(httpheader=header), verbose = TRUE)
  # get ID
  plantlets.raw.result.json<-fromJSON(post.plantlets.results)
  plantlet_id1 <- plantlets.raw.result.json$id
}
cat(plantlet_id1, file = "nm_plantletid.txt")


# 1d. crosses per female plot

crossesid1 = readChar("nm_crossesid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",crossesid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
crosses_id1 <- ''
while(crosses_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.ncrosses.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                    data_value='ArushaCrossesPerFemalePlot.csv',
                                    data_type='media',xform=286910,
                                    data_file=fileUpload(filename = "ArushaCrossesPerFemalePlot.csv",contentType = 'text/csv'),
                                    .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  ncrosses.raw.result.json<-fromJSON(post.ncrosses.results)
  crosses_id1 <- ncrosses.raw.result.json$id
}
cat(crosses_id1, file = "nm_crossesid.txt")

# 1d. status

statusid1 = readChar("nm_statusid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",statusid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
status_id1 <- ''
while(status_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.nstatus.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                   data_value='ArushaPlantStatus.csv',
                                   data_type='media',xform=286910,
                                   data_file=fileUpload(filename = "ArushaPlantStatus.csv",contentType = 'text/csv'),
                                   .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  nstatus.raw.result.json<-fromJSON(post.nstatus.results)
  status_id1 <- nstatus.raw.result.json$id
}
cat(status_id1, file = "nm_statusid.txt")


# 1d. contamination 

contaminationid1 = readChar("nm_contaminationid.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",contaminationid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
contamination_id1 <- ''
while(contamination_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.ncontamination.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                          data_value='ArushaContamination.csv',
                                          data_type='media',xform=286910,
                                          data_file=fileUpload(filename = "ArushaContamination.csv",contentType = 'text/csv'),
                                          .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  ncontamination.raw.result.json<-fromJSON(post.ncontamination.results)
  contamination_id1 <- ncontamination.raw.result.json$id
}
cat(contamination_id1, file = "nm_contaminationid.txt")

q("yes")
