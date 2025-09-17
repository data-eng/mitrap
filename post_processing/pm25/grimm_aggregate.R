library('parallel')

CDepict = function(c){
  v <- c('P','C0:','C0;','c0:','c0;','C1:','C1;','c1:','c1;','C2:','C2;','c2:','c2;','C3:','C3;','c3:','c3;','C4:','C4;','c4:','c4;','C5:','C5;','c5:','c5;','C6:','C6;','c6:','c6;','C7:','C7;','c7:','c7;','C8:','C8;','c8:','c8;','C9:','C9;','c9:','c9;')
  id <- which(v == c)
  return(id)
}

Clean = function(tbl){
  vec <- c(NA,'P','C0:','C0;','c0:','c0;','C1:','C1;','c1:','c1;','C2:','C2;','c2:','c2;','C3:','C3;','c3:','c3;','C4:','C4;','c4:','c4;','C5:','C5;','c5:','c5;','C6:','C6;','c6:','c6;','C7:','C7;','c7:','c7;','C8:','C8;','c8:','c8;','C9:','C9;','c9:','c9;')
  t2 <- tbl[,1]
  index <- c()
  for (i in 1:(length(t2)-1)){
    if (!(CDepict(t2[i])-CDepict(t2[i+1])) %in% c(-1,40)){
      index <- c(index,i)
      i_1 <- i
      i_2 <- i
      while (t2[i_1] != 'c9;'){
        index <- c(index,i_1)
        i_1 <- i_1-1
      }
      while (t2[i_2] != 'P'){
        index <- c(index,i_2)
        i_2 <- i_2+1
      }
    }
  }
  if (t2[length(t2)] != "c9;"){
    a <- length(t2) 
    while (t2[a] != "c9;"){
      index <- c(index,a)
      a <- a-1
    }
  }
  index <- unique(index)
  nfmins <- length(index)
  if (!identical(index, c())){
    rmv <- tbl[-c(index),]
  } else{
    rmv <- tbl
  }
  rows <- nrow(rmv)
  rownames(rmv) <- c(1:rows)
  
  mtemp <- data.frame(matrix(NA, nrow=rows*5/41, ncol=17))
  
  mtemp$X1 <- rep(unlist(c('P','C_:','C_;','c_:','c_;')))
  for (i in 1:(rows/41)){
    for (j in 1:17){
      mtemp[((i-1)*5+1),j] <- rmv[(1+(i-1)*41),j]
    }
    for (j in 2:10){
      for (k in 2:5){
        mtemp[((i-1)*5+k),j]<- 10*mean(as.numeric(c(rmv[((i-1)*41+k),j],rmv[((i-1)*41+k+4),j],rmv[(((i-1)*41+k+2*4)),j],rmv[(((i-1)*41+k+3*4)),j],rmv[(((i-1)*41+k+4*4)),j],rmv[(((i-1)*41+k+5*4)),j],rmv[(((i-1)*41+k+6*4)),j],rmv[(((i-1)*41+k+7*4)),j],rmv[(((i-1)*41+k+8*4)),j],rmv[(((i-1)*41+k+9*4)),j])),na.rm = T)
      }
    }
  }
  for (i in 1:(nrow(mtemp)/5)){
    mtemp$X10[5*i]<-0
  }
  mtemp$X10[mtemp$X10 == 1600]<-160 
  mtemp$X10[is.nan(mtemp$X10)]<-NA 
  return(list(mtemp,nfmins))
  
  
}

SixtoMin_Parallel = function(path){
  cores <- detectCores(logical = 12) # EDW ALLAZEIS TON ARITHMO TWN PYRHNWN POY THELEIS NA XRHSIMOPOIHSEIS #
  table1 <- read.table(as.character(path),fill=T)
  vec <- c(NA,'P','C0:','C0;','c0:','c0;','C1:','C1;','c1:','c1;','C2:','C2;','c2:','c2;','C3:','C3;','c3:','c3;','C4:','C4;','c4:','c4;','C5:','C5;','c5:','c5;','C6:','C6;','c6:','c6;','C7:','C7;','c7:','c7;','C8:','C8;','c8:','c8;','C9:','C9;','c9:','c9;')
  if (!identical(which(!(table1[,1] %in% vec)),integer(0))){
    table <- table1[-c(which(!(table1[,1] %in% vec))),]
    nslines <- length(c(which(!(table1[,1] %in% vec))))
  } else {
    table <- table1
    nslines <- 0
  }
  rows1 <- nrow(table)
  rownames(table) <- c(1:rows1)
  t1 <- table[,1]
  
  cuts <- c()
  sep_points <- c()
  parts <- list()
  for (i in 1:(cores-1)){
    cuts[i] <- ceiling(rows1*(i/cores))
    sep_points[i] <- which(t1[cuts[i]:rows1] == "P")[1]
    sep_points[i] <- cuts[i] + sep_points[i]-1
  }
  sep_points <- c(1,sep_points,rows1)
  for (i in sep_points[1:(length(sep_points)-1)]){
    parts[[which(sep_points == i)]] <- table[sep_points[which(sep_points == i)]:(sep_points[which(sep_points == i)+1]-1),]
  }
  
  clust <- makeCluster(cores) 
  clusterExport(clust, 'CDepict')
  parts1 <- parLapply(clust ,parts[1:(length(sep_points)-1)] ,Clean)
  final <- data.frame()
  nfmins1 <- 0
  for (i in 1:length(parts1)){
    final <- rbind(final,parts1[[i]][[1]])
    nfmins1 <- nfmins1+parts1[[i]][[2]]
  } 
  
  print("Number of non-standard lines found and removed: ") 
  print(nslines)
  print("Number of lines of uncompleted minutes found and removed:") 
  print(nfmins1)
  return(final)
}

Final <- SixtoMin_Parallel("input.grimm")

write.table(Final, "output.csv", sep=",", quote = FALSE, row.names = FALSE, col.names = FALSE, na="" )

