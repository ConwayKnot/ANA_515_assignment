install.packages("bslib",repos = "http://cran.us.r-project.org")
install.packages("tidyverse",repos = "http://cran.us.r-project.org")
install.packages("knitr",repos = "http://cran.us.r-project.org")
install.packages("dplyr",repos = "http://cran.us.r-project.org")
install.packages("lubridate",repos = "http://cran.us.r-project.org")
install.packages("readxl",repos = "http://cran.us.r-project.org")
install.packages("plyr",repos = "http://cran.us.r-project.org")


library("bslib")
library("tidyverse")
library("knitr")
library("dplyr")
library("lubridate")
library("readxl")
library("plyr")


#1.Read the sheets and combine
raw1<- read_excel("GRAIN_RAW.xlsx", sheet=1)
raw2<- read_excel("GRAIN_RAW.xlsx", sheet=2)
raw = rbind(raw1,raw2)

processing = raw
#replace space in column names with underscore
colnames(processing) = gsub(" ", "_", colnames(processing))

#remove any row that contains nothing but N/A
processing <- processing[!apply(is.na(processing) | processing == "", 1, all),]


#2. Unify the terms in column "status of deal"
#there're only 5 valid options, anything else that doesn't correspond to any of these should be N/A
status_types = c("Done","In process", "Complete","Suspended","Proposed")
#select the ones not within these 4
issue_in_status = processing[! processing$Status_of_deal %in% status_types,]
#fixing typos & missing spaces
issue_in_status$Status_of_deal<-revalue(issue_in_status$Status_of_deal, c("Don"="Done", "Inprocess" = "In process","unclear" = NA))

#removing unneeded characters
for (i in 1:length(status_types)) {
  print(status_types[i])
  issue_in_status$Status_of_deal<-ifelse(grepl(status_types[i], issue_in_status$Status_of_deal), status_types[i], issue_in_status$Status_of_deal)
}
#anything else corresponds to N/A
issue_in_status$Status_of_deal<-ifelse(! issue_in_status$Status_of_deal %in% status_types, NA, issue_in_status$Status_of_deal)
#now paste back the processed rows
processing[! processing$Status_of_deal %in% status_types,] = issue_in_status


#3. Fixing the outliers in "Year": first, find all the unrealistic years
year_outlier = processing[(processing$Year<1980 | processing$Year>2100 | is.na(processing$Year)),]
#since there's no way to recover the original date, we just mark them N/A
year_outlier$Year<-c(NA)
#paste back
processing[(processing$Year<1980 | processing$Year>2100 | is.na(processing$Year)),] = year_outlier
processing$Projected_investment_in_millions <- c(NA)


#4. Unify the format of investment and turn into numerical values
# pick out the ones with investment data
inv_exist = processing[(!is.na(processing$Projected_investment)),]
# with data but wrong format
format_wrong = inv_exist[(!grepl("^US\\$\\s*([0-9,\\.]*)\\s*million",inv_exist$Projected_investment)),]
# with data and right format
format_right = inv_exist[grepl("^US\\$\\s*([0-9,\\.]*)\\s*million",inv_exist$Projected_investment),]
# extract the number and remove "," and any other characters
format_right$Projected_investment =  str_match(format_right$Projected_investment, "^US\\$\\s*([0-9,\\.]*)\\s*million")[,2] 
format_right$Projected_investment = gsub(",","",format_right$Projected_investment)
format_right$Projected_investment_in_millions = as.double(format_right$Projected_investment)
format_wrong$Projected_investment<-revalue(format_wrong$Projected_investment, c("---"=NA, "NA" = NA, "0" = NA))
#turn billions to millions
billions = format_wrong[grepl("^US\\$\\s*([0-9,\\.]*)\\s*billion",format_wrong$Projected_investment),]
billions$Projected_investment =  str_match(billions$Projected_investment, "^US\\$\\s*([0-9,\\.]*)\\s*billion")[,2]
billions$Projected_investment = gsub(",","",billions$Projected_investment)
billions$Projected_investment_in_millions = as.double(billions$Projected_investment)*1000

#deal with anything else case-by-case
invalid_investments = format_wrong[!grepl("^US\\$\\s*([0-9,\\.]*)\\s*billion",format_wrong$Projected_investment),]
invalid_investments$Projected_investment<-revalue(invalid_investments$Projected_investment, c("500 million US"=500, "$336 million dollars" = 336,"66$" = NA, "US$30-35 million" = "32.5", "1.5 million dollars US" = 1.5))

#wrong data -> N/A
invalid_investments$Projected_investment<-ifelse(grepl("/yr", invalid_investments$Projected_investment), NA, invalid_investments$Projected_investment)
invalid_investments$Projected_investment<-ifelse(grepl("/ha", invalid_investments$Projected_investment), NA, invalid_investments$Projected_investment)
invalid_investments$Projected_investment_in_millions = as.double(invalid_investments$Projected_investment)

format_wrong[!grepl("^US\\$\\s*([0-9,\\.]*)\\s*billion",format_wrong$Projected_investment),] = invalid_investments
format_wrong[grepl("^US\\$\\s*([0-9,\\.]*)\\s*billion",format_wrong$Projected_investment),] = billions

#Now paste everything back
processing[(!is.na(processing$Projected_investment)),][(grepl("^US\\$\\s*([0-9,\\.]*)\\s*million",inv_exist$Projected_investment)),] = format_right
processing[(!is.na(processing$Projected_investment)),][(!grepl("^US\\$\\s*([0-9,\\.]*)\\s*million",inv_exist$Projected_investment)),] = format_wrong

#remove the original column
processing = processing %>% subset(select=-c(Projected_investment))


#5. unify the terms in "Sector"
#sector_types = c ("agribusiness", "construction", "energy", "finance", "Real estate", "Industrial", "government", "telecommunications", "information technology", "mining")
processing$Sector<-tolower(processing$Sector)
# unify the terms and convert all to lower case
# now every entry is one or multiple valid terms separated by commas
processing$Sector<-gsub("ab","agribusiness",processing$Sector)
processing$Sector<-gsub("fin,","finance,",processing$Sector)
processing$Sector<-gsub(",fin",",finance",processing$Sector)
processing$Sector<-gsub("fin$","finance$",processing$Sector)
processing$Sector<-gsub(",,,",",",processing$Sector)
#unknown terms -> N/A
processing$Sector<-revalue(processing$Sector, c("na"=NA, "ngo"=NA))


#6. unify the terms in "Production"
#the original looks fine, just convert all to lower case so that the terms are unified
processing$Production<-tolower(processing$Production)

#7. "landgrabbed"
#use N/A as the only indicator of missing data
processing$Landgrabbed<-revalue(processing$Landgrabbed, c("---"=NA))

#8. "base"
#should only use one name for each country
processing$Base<-revalue(processing$Base, c("UNITED STATES"="US","United Kingdom"="UK","Fran"="France","Gemany"="Germany","--"=NA, "NA"=NA))

#9. "landgrabber"
#the quoted landgrabber are unclear but some still contains useful info
#I removed the ones that are too vague and doesn't add anything useful
questionable_landgrabber = processing[grepl("\"",processing$Landgrabber),]
questionable_landgrabber$Landgrabber<-revalue(questionable_landgrabber$Landgrabber,c("\"Chinese investors\""=NA, 	"\"Chinese investment group\""=NA))
#paste back
processing[grepl("\"",processing$Landgrabber),] = questionable_landgrabber

write.csv(processing,'data_processed.csv')

#plots
library("ggplot2")
p1 <-processing %>% na.omit() %>% ggplot(aes(x=Year,y=Projected_investment_in_millions))+geom_point(aes(color=Base))
p1

p2 <-processing %>% na.omit() %>% ggplot(aes(x=Year,y=Hectares))+geom_point(aes(color=Status_of_deal))
p2
