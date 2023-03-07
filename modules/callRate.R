library(dplyr)
library(stringr)
library(ggplot2)

dat <- read.table("postcalling_qc/callRate_bychr.txt", header=FALSE, sep="\t")
colnames(dat)=c("CHROM","MISSING_RATE")

dat2 <- read.table("postcalling_qc/GT.txt", header=TRUE, sep="\t")

jpeg(filename = "postcalling_qc/callRate_bychr.jpeg", width = 1000, height = 480, units = "px",bg ="white")

ggplot(dat, aes(x=CHROM, y=MISSING_RATE)) +
geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
ggtitle("Missing Call(./.) Rate across All Variants by Chromosome") +
theme(panel.grid = element_line(color = "grey", size = 0.5, linetype = 1), plot.title = element_text(hjust = 0.5))

dev.off()

sink("postcalling_qc/callRate_bychr.quantile.txt")
q = c(.0, .25, .5, .75, 1.0)
quantile <- dat %>%
  group_by(CHROM) %>%
  summarize(quant0  = quantile(MISSING_RATE, probs = q[1]),
	        quant25 = quantile(MISSING_RATE, probs = q[2]), 
            quant50 = quantile(MISSING_RATE, probs = q[3]),
            quant75 = quantile(MISSING_RATE, probs = q[4]),
            quant100 = quantile(MISSING_RATE, probs = q[5]))

print(as_tibble(quantile),n = 25)
sink()

CallRate <- dat2%>%
summarise(across(everything(),
~sum(str_count(.x, "\\./\\."))/n()))  #count the occurence of "./" using str_count from library(stringr)

#append the first element in each col name field into a list 
li = list()
for (i in 3:length(str_split(colnames(CallRate),"_"))){li <- append(li,str_split(colnames(CallRate),"_")[[i]][1])}

CallRate2 = CallRate%>% select(-c(CHROM,POS)) #remove chr and pos columns
callRateSamp = as.data.frame(t(CallRate2))
callRateSamp$group = unlist(li)

colnames(callRateSamp)=c("MISSING_RATE","GROUP")

jpeg(filename = "postcalling_qc/callRate_byGroup.jpeg")

ggplot(callRateSamp, aes(x=GROUP, y=MISSING_RATE)) +
geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
ggtitle("Missing Call(./.) Rate across All Samples by Group") +
theme(panel.grid = element_line(color = "grey", size = 0.5, linetype = 1), plot.title = element_text(hjust = 0.5))

dev.off()

