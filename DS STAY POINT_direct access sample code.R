#API authentication token generation
  consumer.key <- "YOUR CONSUMER KEY"
consumer.secret <- "YOUR CONSUMER SECRET"
key.secret.b64 <- base64_encode(paste(consumer.key, consumer.secret, sep = ":"))
token.response <- POST("https://apistore.datasparkanalytics.com/token",
                       body = "grant_type=client_credentials",
                       add_headers(Authorization = paste("Basic", key.secret.b64)))
token <- content(token.response)$access_token

#Query body
query.body <- list(
  date = "2017-12-24",
  location = list(locationType = "locationHierarchyLevel", levelType = "staypoint_subzone", id = "SRSZ03"),
  queryGranularity = list(type = "period", period = "P1D"),
  aggregations = list(list(metric = "total_stays", type = "longSum", describedAs = "total_stay"),
                      list(metric = "sum_stay_duration", type = "longSum", describedAs = "total_stay_duration")),
  #Optional parameters:
  filter = list(type="selector",dimension="agent_gender",value="M"),
  dimensionFacets = list("agent_home_planningregion")
  )


# token variable contains a valid access token; see Getting Started.
query.response <- POST("https://apistore.datasparkanalytics.com:8243/staypoint/v2/query",
                       add_headers(Authorization = paste("Bearer", token)),
                       encode = "json",
                       body = query.body, verbose())

#convert query response from JSON to data frame

data <- fromJSON(rawToChar(query.response$content))
data.df <- do.call(what = "cbind", args = lapply(data, as.data.frame))
names(data.df)[1] = names(data[1])

#Optional: export data frame in csv format
filename <- paste0("DS SP API",format(Sys.time(),"%y%m%d_%H%M"),".csv")
write.csv(data.df, file = filename)
