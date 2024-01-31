library(readr)

os.grid.to.lat.lon <- function(E, N) {
  
  a <- 6377563.396
  b <- 6356256.909
  F0 <- 0.9996012717
  lat0 <- 49*pi/180
  lon0 <- -2*pi/180
  N0 <- -100000
  E0 <- 400000
  e2 <- 1 - (b^2)/(a^2)
  n <- (a-b)/(a+b)
  n2 <- n^2
  n3 <- n^3
  
  lat <- lat0
  M <- 0
  
  repeat {
    
    lat <- (N-N0-M)/(a*F0) + lat
    
    Ma <- (1 + n + (5/4)*n2 + (5/4)*n3) * (lat-lat0)
    Mb <- (3*n + 3*n*n + (21/8)*n3) * sin(lat-lat0) * cos(lat+lat0)
    Mc <- ((15/8)*n2 + (15/8)*n3) * sin(2*(lat-lat0)) * cos(2*(lat+lat0))
    Md <- (35/24)*n3 * sin(3*(lat-lat0)) * cos(3*(lat+lat0))
    M <- b * F0 * (Ma - Mb + Mc - Md)
    
    if (N-N0-M < 0.00001) { break }
    
  }
  
  cosLat <- cos(lat)
  sinLat <- sin(lat)
  
  nu <- a*F0/sqrt(1-e2*sinLat*sinLat)
  rho <- a*F0*(1-e2)/((1-e2*sinLat*sinLat)^1.5)
  
  eta2 <- nu/rho-1
  
  tanLat <- tan(lat)
  tan2lat <- tanLat*tanLat
  tan4lat <- tan2lat*tan2lat
  tan6lat <- tan4lat*tan2lat
  
  secLat <- 1/cosLat
  nu3 <- nu*nu*nu
  nu5 <- nu3*nu*nu
  nu7 <- nu5*nu*nu
  
  VII <- tanLat/(2*rho*nu)
  VIII <- tanLat/(24*rho*nu3)*(5+3*tan2lat+eta2-9*tan2lat*eta2)
  IX <- tanLat/(720*rho*nu5)*(61+90*tan2lat+45*tan4lat)
  X <- secLat/nu
  XI <- secLat/(6*nu3)*(nu/rho+2*tan2lat)
  XII <- secLat/(120*nu5)*(5+28*tan2lat+24*tan4lat)
  XIIA <- secLat/(5040*nu7)*(61+662*tan2lat+1320*tan4lat+720*tan6lat)
  
  dE <- (E-E0)
  dE2 <- dE*dE
  dE3 <- dE2*dE
  dE4 <- dE2*dE2
  dE5 <- dE3*dE2
  dE6 <- dE4*dE2
  dE7 <- dE5*dE2
  
  lon <- lon0 + X*dE - XI*dE3 + XII*dE5 - XIIA*dE7
  lat <- lat - VII*dE2 + VIII*dE4 - IX*dE6
  
  lat <- lat * 180/pi
  lon <- lon * 180/pi
  
  return(c(lat, lon))
  
}


# takes a string OS reference and returns an E/N vector

os.grid.parse <- function(grid.ref) {
  
  grid.ref <- toupper(grid.ref)
  
  # get numeric values of letter references, mapping A->0, B->1, C->2, etc:
  l1 <- as.numeric(charToRaw(substr(grid.ref,1,1))) - 65
  l2 <- as.numeric(charToRaw(substr(grid.ref,2,2))) - 65
  
  # shuffle down letters after 'I' since 'I' is not used in grid:
  if (l1 > 7) l1 <- l1 - 1
  if (l2 > 7) l2 <- l2 - 1
  
  # convert grid letters into 100km-square indexes from false origin - grid square SV
  
  e <- ((l1-2) %% 5) * 5 + (l2 %% 5)
  n <- (19 - floor(l1/5) *5 ) - floor(l2/5)
  
  if (e<0 || e>6 || n<0 || n>12) { return(c(NA,NA)) }
  
  # skip grid letters to get numeric part of ref, stripping any spaces:
  
  ref.num <- gsub(" ", "", substr(grid.ref, 3, nchar(grid.ref)))
  ref.mid <- floor(nchar(ref.num) / 2)
  ref.len <- nchar(ref.num)
  
  if (ref.len >= 10) { return(c(NA,NA)) }
  
  e <- paste(e, substr(ref.num, 0, ref.mid), sep="", collapse="")
  n <- paste(n, substr(ref.num, ref.mid+1, ref.len), sep="", collapse="")
  
  nrep <- 5 - match(ref.len, c(0,2,4,6,8))
  
  e <- as.numeric(paste(e, "5", rep("0", nrep), sep="", collapse=""))
  n <- as.numeric(paste(n, "5", rep("0", nrep), sep="", collapse=""))
  
  return(c(e,n))
  
}

library(dplyr)

#remove na values
Clean = filter(Flood_risk_asset_register, !is.na(features.properties.CNTR_X))

#add row numbers
Clean$index <- 1:nrow(Clean)

#create sequence for for loop
slices = unique(Clean$index)

#create empty dataframe
Zero = data.frame()

#generate for loop of all Lat Long
for(v in slices){
  row = filter(Clean[c(7,8,10)], index == v)
  results = as.data.frame(t(os.grid.to.lat.lon(row[1],row[2])))
  Zero = rbind(results,Zero)
}
#change column names
colnames(Zero) <- c("Lat", "Long")
#append Lat and Long
FloodwithLatLong = cbind(Clean, Zero)
FloodRisk = FloodwithLatLong[c(7,8,11,12)]
#write out csv
write.csv(FloodRisk,"FloodRiskwithLatLong.csv", row.names = FALSE)
class(FloodwithLatLong)

library(readr)

# First coerce the data.frame to all-character
FloodRiskToCSV = data.frame(lapply(FloodRisk, as.character), stringsAsFactors=FALSE)

# write file
write.csv(FloodRiskToCSV,"FloodRiskwithLatLong.csv", row.names = FALSE)


