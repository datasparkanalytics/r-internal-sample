

#This is a script template to call the OD Matrix API for multiple dates and/or multiple locations
#code written for R version 3.4.1 (2017-06-30) -- "Single Candle"

#How to use this script
#1. Set the appropriate working directory where you want the data exports to be saved in, 
#   replace the directory below with the right directory.
setwd("C:/Users/B/Documents/01_Singtel Work/API analysis")

#3. Source the current script
#4. Call the following function:
#
#   dsapi.od.mdml (fromdate,todate,areas,timereference = "origin",
#     hierarchy = "origin_subzone", interval = "PT1H",
#     output = list(uniqueVisit,totalVisit,totalDuration,totalDistance), 
#     dimension = NULL,filters = NULL)
#
#   User need to input three mandatory parameters:
#     fromdate - first date of date range interested (format:YYYY-MM-DD), 
#     todate - last date of date range interested (format:YYYY-MM-DD),
#     areas - list of codes of areas of interest(e.g., list("GLSZ04","BMSZ10")), 
#   There are five parameters with defaul value:
#     timereference - enter "origin" if using origin location to query, enter "destination" 
#                     if using destination location to query
#     interval - enter reporting interval (format in PnDTnHnMnS), default at hourly interval (e.g., "PT1H)
#     output - list of outputS(s) of interest, default set as list(uniqueVisit). 
#     dimension - allows you to set dimensions to group the results by, default value is
#                     NULL (e.g., list("agent_gender","agent_race")),
#     hierarchy - location hierarchy config, can choose from origin or destination, and hierarchy from subzone, 
#                     planning area, planning region (e.g., "origin_subzone")
#     filters - allows you to put in optional filters, should be in the form of a list


#Load relevant packages
library("httr")
library("jsonlite")
library("dplyr")
library("openssl")

#API authentication
consumer.key <- "ytydJ53JjqOyUefbu98oqQCa1jga"
consumer.secret <- "fCxoqX19Wr87mtxySAWPeaDYPdQa"
key.secret.b64 <- base64_encode(paste(consumer.key, consumer.secret, sep = ":"))
token.response <- POST("https://apistore.datasparkanalytics.com/token",
                       body = "grant_type=client_credentials",
                       add_headers(Authorization = paste("Basic", key.secret.b64)))
token <- content(token.response)$access_token


#Define outputs, uniqueVisit gives an output of unique visitors as output, totalVisit gives
#an output of total visits

uniqueVisit <- list(metric = "unique_agents", type = "hyperUnique", describedAs = "unique_people")
totalVisit <- list(metric = "total_records", type = "longSum", describedAs = "total_trips")
totalDuration <- list(metric = "sum_duration", type = "longSum", describedAs = "total_duration")
totalDistance <- list(metric = "sum_distance", type = "longSum", describedAs = "total_distance")

#A function to call the OD matrix API

dsapi.od <- function(p_Date,area, timereference = "origin",
                        hierarchy = "origin_subzone", interval = "PT1H",
                        output = list(uniqueVisit,totalVisit,totalDuration,totalDistance), 
                        dimension = NULL,filters = NULL){
  
  #Query body with all the parameters listed
  query.body <- list(
    date = p_Date,
    timeSeriesReference = timereference,
    location = list(locationType = "locationHierarchyLevel", levelType = hierarchy, id = area),
    queryGranularity = list(type = "period", period = interval),
    dimensionFacets = dimension,
    aggregations = output,
    filter = filters
  )
  
  
  # token variable contains a valid access token; see Getting Started.
  query.response <- POST("https://apistore.datasparkanalytics.com:8243/odmatrix/v3/query",
                         add_headers(Authorization = paste("Bearer", token)),
                         encode = "json",
                         body = query.body, verbose())
  
  #optional for QA
  stop_for_status(query.response)
  cat(content(query.response, as = "text"), "\n")
  
  #convert query response from JSON to data frame
  
  data <- fromJSON(rawToChar(query.response$content))
  data.df <- do.call(what = "cbind", args = lapply(data, as.data.frame))
  names(data.df)[1] = names(data[1])
  
  return(data.df)
  
}


# If you want to query for multiple dates and multiple locations

dsapi.od.mdml <- function(fromdate,todate,areas,timereference = "origin",
                             hierarchy = "origin_subzone", interval = "PT1H",
                             output = list(uniqueVisit,totalVisit,totalDuration,totalDistance), 
                          dimension = NULL,filters = NULL){
  
  daterange <- as.list(seq(as.Date(fromdate), as.Date(todate), by="days")) #date range of interest
  area_list <- areas #enter a list of codes of subzones of interest(e.g., list("GLSZ04","BMSZ10"))
  t <- timereference #enter "origin" if using origin location to query, enter "destination" if using destination location to query
  y <- output #enter output of interest, uniqueVisit or totalVisit
  z <- dimension #enter reporting dimensions as a list (e.g. list("agent_gender","agent_race")), if not relevant, input "NULL"
  h <- hierarchy #location hierarchy config, can choose from origin or destination, and hierarchy from subzone, planning area, planning region (e.g., "discrete_visit_subzone")
  p <- interval #enter reporting interval (format in PnDTnHnMnS), default at hourly interval (e.g., "PT1H)
  f <- filters #optional filtering objects, need to be input as a list
  
  new.df <- data.frame()
  
  for (i in daterange) {
    for (j in area_list){
      data.df <- dsapi.od (i,j,t,h,p,y,z,f)
      new.df <- rbind(new.df, data.df)}
  }
  
  str(new.df)
  
  filename <- paste0("DS OD API",format(Sys.time(),"%y%m%d_%H%M"),".csv")
  write.csv(new.df, file = filename)
  
}
