#API authentication token generation
consumer.key <- "ytydJ53JjqOyUefbu98oqQCa1jga"
consumer.secret <- "fCxoqX19Wr87mtxySAWPeaDYPdQa"
key.secret.b64 <- base64_encode(paste(consumer.key, consumer.secret, sep = ":"))
token.response <- POST("https://apistore.datasparkanalytics.com/token",
                       body = "grant_type=client_credentials",
                       add_headers(Authorization = paste("Basic", key.secret.b64)))
token <- content(token.response)$access_token

#Query body
query.body <- list(
  date = "2017-11-02",
  location = list(locationType = "locationHierarchyLevel", levelType = "discrete_visit_subzone", id = "RCSZ05"),
  queryGranularity = list(type = "period", period = "PT1H"),
  aggregations = list(list(metric = "unique_agents", type = "hyperUnique", describedAs = "footfall")),
  #Optional parameters:
  filter = list(type="bound",dimension="agent_year_of_birth",lower="1992",upper="1998",ordering="numeric"),
  dimensionFacets = list("agent_gender")
  )


# token variable contains a valid access token; see Getting Started.
query.response <- POST("https://apistore.datasparkanalytics.com:8243/discretevisit/v2/query",
                       add_headers(Authorization = paste("Bearer", token)),
                       encode = "json",
                       body = query.body, verbose())

#convert query response from JSON to data frame

data <- fromJSON(rawToChar(query.response$content))
data.df <- do.call(what = "cbind", args = lapply(data, as.data.frame))
names(data.df)[1] = names(data[1])

#Optional: export data frame in csv format
filename <- paste0("DS DV API",format(Sys.time(),"%y%m%d_%H%M"),".csv")
write.csv(data.df, file = filename)
