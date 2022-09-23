
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

# ++++++++++++++++++++++++ SENDUSU ++++++++++++++++++++++++++++++++++++++++++++

# 2a. flowering

flowerid2 <- readChar("flowerid_se.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",flowerid2),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# post
flower_id2 <- ''
while(flower_id2 == ''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.flower.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='SendusuFlowering.csv',
                                  data_type='media',
                                  xform=313930,
                                  data_file=fileUpload(filename = "SendusuFlowering.csv",contentType = 'text/csv'),
                                  .opts=list(httpheader=header), verbose = TRUE)
  
  # ID
  flower.raw.result.json<-fromJSON(post.flower.results)
  flower_id2 <- flower.raw.result.json$id
}
cat(flower_id2, file = "flowerid_se.txt")


# 2b. banana

bananaid2 <- readChar("bananaid_se.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",bananaid2),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# post 
banana_id2 <- ''
while(banana_id2 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), 
           `Content-Type` = 'multipart/form-data')
  post.banana.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                  data_value='SendusuBananaData.csv',
                                  data_type='media',
                                  xform=313930,
                                  data_file=fileUpload(filename = "SendusuBananaData.csv",contentType = 'text/csv'),
                                  
                                  .opts=list(httpheader=header), verbose = TRUE)
  # ID
  banana.raw.result.json<-fromJSON(post.banana.results)
  banana_id2 <- banana.raw.result.json$id
}
cat(banana_id2, file = "bananaid_se.txt")


# 2c.. Plantlets

plantletid2 = readChar("plantletid_se.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",plantletid2),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
plantlet_id2 <- ''
while(plantlet_id2 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY), 
           `Content-Type` = 'multipart/form-data')
  post.plantlets.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                     data_value='SendusuPlantlets.csv',
                                     data_type='media',
                                     xform=313930,
                                     data_file=fileUpload(filename = "SendusuPlantlets.csv",contentType = 'text/csv'),
                                     .opts=list(httpheader=header), verbose = TRUE)
  # get ID
  plantlets.raw.result.json<-fromJSON(post.plantlets.results)
  plantlet_id2 <- plantlets.raw.result.json$id
}
cat(plantlet_id2, file = "plantletid_se.txt")


# 2d. crosses per female plot

crossesid2 = readChar("crossesid_se.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",crossesid2),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
crosses_id2 <- ''
while(crosses_id2 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.ncrosses.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                    data_value='SendusuCrossesPerFemalePlot.csv',
                                    data_type='media',
                                    xform=313930,
                                    data_file=fileUpload(filename = "SendusuCrossesPerFemalePlot.csv",contentType = 'text/csv'),
                                    .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  ncrosses.raw.result.json<-fromJSON(post.ncrosses.results)
  crosses_id2 <- ncrosses.raw.result.json$id
}
cat(crosses_id2, file = "crossesid_se.txt")

# 1d. status 

statusid1 = readChar("statusid_se.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",statusid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
status_id1 <- ''
while(status_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.nstatus.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                   data_value='SendusuPlantStatus.csv',
                                   data_type='media',xform=313930,
                                   data_file=fileUpload(filename = "SendusuPlantStatus.csv",contentType = 'text/csv'),
                                   .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  nstatus.raw.result.json<-fromJSON(post.nstatus.results)
  status_id1 <- nstatus.raw.result.json$id
}
cat(status_id1, file = "statusid_se.txt")

# 1d. contamination 

contaminationid1 = readChar("contaminationid_se.txt", 10)
hdr=c(Authorization=paste("Temptoken ",TOKEN_KEY))
DELETE(paste("https://api.ona.io/api/v1/metadata/",contaminationid1),
       add_headers(Authorization=paste("Temptoken ",TOKEN_KEY)))

# upload
contamination_id1 <- ''
while(contamination_id1 ==''){
  header=c(Authorization=paste("Temptoken ", TOKEN_KEY),
           `Content-Type` = 'multipart/form-data')
  post.ncontamination.results <- postForm("https://api.ona.io/api/v1/metadata.json",
                                          data_value='SendusuContamination.csv',
                                          data_type='media',xform=313930,
                                          data_file=fileUpload(filename = "SendusuContamination.csv",contentType = 'text/csv'),
                                          .opts=list(httpheader=header), verbose = TRUE)
  # get  ID
  ncontamination.raw.result.json<-fromJSON(post.ncontamination.results)
  contamination_id1 <- ncontamination.raw.result.json$id
}
cat(contamination_id1, file = "contaminationid_se.txt")

q("yes")
