library(SparkR)	
text_file <- "hdfs://my_text_file"
lines	<-	textFile(sc, text_file)	
words	<-	flatMap(lines,	
                 function(line)	{	
                   strsplit(line,	"	")[[1]]	
                 })	

wordCount	<-	lapply(words,		
                    function(word)	{		
                      list(word,	1L)		
                    })	

counts	<-	reduceByKey(wordCount,	"+",	2L)	
output	<-	collect(counts)	