#query designed specifically for NPDES permit writers for RPA analysis. It calls necessary data from VW_AWQMS_Results using an ODBC connection
#this query is based off of Travis Pritchard's AWQMS_Data query
#This query will only return Water data from the following station types:
#'BEACH Program Site-Ocean','BEACH Program Site-River/Stream',
#'Canal Drainage','Canal Irrigation','Canal Transport','Estuary','Facility Industrial',
#'Facility Municipal Sewage (POTW)','Facility Other','Lake','Ocean','Reservoir','River/Stream',
#'River/Stream Perennial'
# in additon, the query is set up so that when Reject=False (default), no rejected data will be returned

NPDES_AWQMS_Qry<-function 
(startdate = "2000-01-01", enddate = NULL, station = NULL, char = NULL, org = NULL, 
 HUC8 = NULL, HUC8_Name = NULL,reject=FALSE) 
{
  if (missing(startdate)) {
    stop("Need to input startdate")
  }
  if (startdate<'2000-01-01'){stop("StartDate prior to 2000")}
  query <- "SELECT OrganizationID,StationDes, MonLocType,act_id,SampleStartDate,SampleMedia,SampleSubmedia,Activity_Type,Statistical_Base,Time_Basis,Char_Name,Char_Speciation,
  Sample_Fraction,CASNumber,Result,Result_Unit,Analytical_method,MDLType,MDLValue,MDLUnit,MRLType,MRLValue,MRLUnit,
  Result_status,Result_Type\n  FROM [awqms].[dbo].[VW_AWQMS_Results]\n  
  WHERE SampleStartDate >= Convert(datetime, {startdate})"
  if (length(enddate) > 0) {
    query = paste0(query, "\n AND SampleStartDate <= Convert(datetime, {enddate})")
  }
  if (length(station) > 0) {
    query = paste0(query, "\n AND MLocID IN ({station*})")
  }
  if (length(char) > 0) {
    query = paste0(query, "\n AND Char_Name in ({char*}) ")
  }
  if (length(org) > 0) {
    query = paste0(query, "\n AND OrganizationID in ({org*}) ")
  }
  if (length(HUC8) > 0) {
    query = paste0(query, "\n AND HUC8 in ({HUC8*}) ")
  }
  if (length(HUC8_Name) > 0) {
    query = paste0(query, "\n AND HUC8_Name in ({HUC8_Name*}) ")
  }
  if (reject==FALSE) {query=paste0(query,"\n AND Result_status NOT LIKE 'Rejected'")}
  query=paste0(query,"\n AND SampleMedia in ('Water')")
  query=paste0(query,"\n AND MonLocType in ('BEACH Program Site-Ocean','BEACH Program Site-River/Stream',
               'Canal Drainage','Canal Irrigation','Canal Transport','Estuary','Facility Industrial',
               'Facility Municipal Sewage (POTW)','Facility Other','Lake','Ocean','Reservoir','River/Stream',
               'River/Stream Perennial')")
  query=paste0(query,"\n AND MLocID <> '10000-ORDEQ'\n                   \n AND activity_type NOT LIKE 'Quality Control%'")
  
  con <- DBI::dbConnect(odbc::odbc(), "AWQMS")
  qry <- glue::glue_sql(query, .con = con)
  data_fetch <- DBI::dbGetQuery(con, qry)
  DBI::dbDisconnect(con)
  return(data_fetch)
}


#data<-NPDES_AWQMS_Qry(startdate='2000-01-01',enddate='2018-12-27')


#####create function like AWQMS_Stations but only pulls desired station types 
#(hoping to cut down on time for Shiny app by cutting out extra stuff)

NPDES_AWQMS_Stations<-function (char = NULL, HUC8 = NULL, HUC8_Name = NULL, 
          org = NULL) 
{
  con <- DBI::dbConnect(odbc::odbc(), "AWQMS")
  query = "SELECT distinct  [MLocID], [StationDes], [MonLocType], [EcoRegion3], [EcoRegion4], [HUC8], [HUC8_Name], [HUC10], [HUC12], [HUC12_Name], [Lat_DD], [Long_DD], [Reachcode], [Measure], [AU_ID]\n  FROM [awqms].[dbo].[VW_AWQMS_Results]"
  
  query<-paste0(query,"\n WHERE MonLocType in ('BEACH Program Site-Ocean','BEACH Program Site-River/Stream',
               'Canal Drainage','Canal Irrigation','Canal Transport','Estuary','Facility Industrial',
                  'Facility Municipal Sewage (POTW)','Facility Other','Lake','Ocean','Reservoir','River/Stream',
                  'River/Stream Perennial')")

  if (length(char) > 0) {
      query <- paste0(query, "\n AND Char_Name IN ({char*})")
    }
  
  if (length(HUC8) > 0) {
    if (length(char > 0)) {
      query = paste0(query, "\n AND HUC8 IN ({HUC8*})")
    }
    else {
      query <- paste0(query, "\n AND HUC8 IN ({HUC8*})")
    }
  }
  if (length(HUC8_Name) > 0) {
    if (length(char > 0) | length(HUC8) > 
        0) {
      query = paste0(query, "\n AND HUC8_Name in ({HUC8_Name*}) ")
    }
    else {
      query <- paste0(query, "\n AND HUC8_Name IN ({HUC8_Name*})")
    }
  }
  if (length(org) > 0) {
    if (length(char > 0) | length(HUC8) > 
        0 | length(HUC8_Name) > 0) {
      query = paste0(query, "\n AND OrganizationID in ({org*}) ")
    }
    else {
      query <- paste0(query, "\n AND OrganizationID in ({org*}) ")
    }
    
  }
  qry <- glue::glue_sql(query, .con = con)
  data_fetch <- DBI::dbGetQuery(con, qry)
  DBI::dbDisconnect(con)
  return(data_fetch)
}

#stat<-NPDES_AWQMS_Stations()