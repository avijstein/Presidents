# All of the Presidents #
library(tidyverse)
library(lubridate)

setwd('~/Desktop/Real Life/Coding Projects/Presidents/')

# plotting sytle options.
clean_plot =  theme(axis.line = element_line(colour = "blue"), panel.grid.major = element_blank(),
                    panel.grid.minor = element_blank(), panel.border = element_blank(),
                    panel.background = element_blank(), legend.key = element_blank())

##### READING IN DATA #####
pres1 = read.csv('presidents1.csv', stringsAsFactors = F)
pres2 = read.csv('presidents2.csv', stringsAsFactors = F)

##### CLEANING UP DATA ####

# we just want the president's name
pres2$justPresident = substr(pres2$President, 1, (regexpr('\\(', pres2$President)-2) )
pres2 = pres2[,c(3,2)]
names(pres2) = c('President', 'First Elected')

# cleaning up a few middle name errors:
pres2[pres2$`First Elected` == 1933,]$President = 'Franklin Roosevelt'
pres2[pres2$`First Elected` == 1953,]$President = 'Dwight Eisenhower'


# clean up the birth dates (this was a hot mess)
sec1 = pres1[1:33,1:2] # selecting one type of date format
sec2 = pres1[34:nrow(pres1),1:2] # the other type of date format
sec1$newBirth = as.Date(sec1$Birth.Date, format = '%b %d, %Y') # converting them to dates
sec2$newBirth = as.Date(sec2$Birth.Date, format = '%d-%b-%y') # trying to convert to dates

# if they were born in "17," it assumed 2017, not 1917 or any other century. This turned them into a string,
# then changed the first two letters into "19."
sec2$newBirth = as.Date(sapply(as.character(sec2$newBirth), function(x) gsub(x, pattern = substr(x,1,2), replacement = '19')))

# put the pieces back together for their birth dates.
sec3 = rbind(sec1[,c(1,3)],sec2[,c(1,3)])
pres1 = merge(pres1, sec3, by = 'President')

# cleaning up the death dates
sec1 = pres1[order(pres1$Death.Date),][1:17,] # selecting one type of date format.
sec2 = pres1[order(pres1$Death.Date),][18:38,] #selecting the other date format.
# some presidents are still alive, so we exclude NAs for now.
sec2$newDeath = as.Date(sec2$Death.Date, format = '%b %d, %Y') # first conversion attempt
sec1$newDeath = as.Date(sec1$Death.Date, format = '%d-%b-%y') # first conversion attempt
sec1$newDeath = as.character(sec1$newDeath) # characters are easier to modify here.
sec1 = sec1[order(sec1$newBirth),] # ordering so we can quickly grab those who died before 2000.
sec4 = sec1[c(1:10,17),] # selecting those who died before 2000 (old guys + Kennedy).
# this is the same step as before, substituting in for the last century.
sec4$newDeath = as.Date(sapply(as.character(sec4$newDeath), function(x) gsub(x, pattern = substr(x,1,2), replacement = '19')))
# put these back together with only pertinent information.
sec5 = merge(sec1[,c('President', 'newBirth')], sec4[,c('President', 'newDeath')], by = 'President')

# only selecting presidents didn't need correcting.
sec6 = sec1[!sec1$President %in% sec4$President,c('President', 'newBirth', 'newDeath')]
sec7 = rbind(sec5, sec6) # putting these pieces together.

# combining the problem childs and the one-step conversions.
sec8 = rbind(sec2[,c('President', 'newBirth', 'newDeath')], sec7)

# taking care of the NAs
sec9 = pres1[is.na(pres1$Death.Date),]
sec9$newDeath = NA
sec9 = sec9[,c('President', 'newBirth', 'newDeath')]

# adding in the NAs.
sec10 = rbind(sec8, sec9)

# rewriting pres1
pres1 = sec10

# creating a final, functional pres3 with all date information in Date format.
pres3 = merge(pres1, pres2, by = 'President')

##### MORE STATS OF INTEREST #####

pres3$shortBirth = as.numeric(substr(as.character(cut(pres3$newBirth, breaks = 'years')), 1,4))
pres3$shortDeath = as.numeric(substr(as.character(cut(pres3$newDeath, breaks = 'years')), 1,4))

pres3$first_elected = pres3$`First Elected`
pres3$life = pres3$shortDeath - pres3$shortBirth
pres3$elected_age = pres3$`First Elected` - pres3$shortBirth
pres3$remaining_life = pres3$life - pres3$elected_age

# presidents alive each decade
decades = data.frame('time' = seq(1780,2020,10))
for (i in 1:nrow(decades)){
  decades$alive[i] = nrow(pres3[(pres3$shortDeath > decades$time[i] & pres3$shortBirth < decades$time[i]),])
}

# terms for each president
terms = data.frame('time' = pres3$first_elected[order(pres3$first_elected)])
for (i in 1:nrow(terms)){
  terms$term[i] = terms$time[i+1] - terms$time[i]
}

# cleaning up code for the markdown document
temp1 = pres3[order(pres3$first_elected),c(1,5,7,6)]
names(temp1) = c('President', 'BirthYear', 'FirstElected', 'DeathYear')
p1 = temp1

# cleaning up code for the markdown document
temp2 = pres3[order(pres3$first_elected),c(1,8:10)]
names(temp2) = c('President', 'Lifespan', 'ElectedAge', 'RemainingYears')
p2 = temp2


# zodiac signs for presidents
zodiac = data.frame('sign' = c('Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio',
                               'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'),
                    'start_dates' = (c('Mar 21', 'Apr 21', 'May 21', 'Jun 22', 'Jul 23', 'Aug 24',
                                              'Sep 24', 'Oct 24', 'Nov 23', 'Dec 22', 'Jan 21', 'Feb 19')))

zodiac$start2 = as.Date(zodiac$start_dates, format = '%b %d')
zodiac$start = as.numeric(strftime(zodiac$start2, format = "%j"))
zodiac = zodiac[order(-zodiac$start),]
zodiac$end = zodiac$start - 1
zodiac$end = c(zodiac$end[c(nrow(zodiac), 2:nrow(zodiac)-1)])
zodiac$count = 0
zodiac = zodiac[,-c(2,3)]

# binning the presidents
zpres = as.numeric(strftime(pres3$newBirth, format = '%j'))
zpres2 = data.frame('DOY' = zpres, 'cat' = cut(zpres, breaks = zodiac$end, labels = F))
zpres2[is.na(zpres2$cat),] = 12
zodiac$count = table(zpres2$cat)
zodiac$count = as.integer(zodiac$count)


##### GRAPHING #####

# graphing over time
ggplot(data = pres3, aes(x = first_elected)) +
  # geom_point(aes(y = life), color = 'slateblue1') +
  geom_point(aes(y = elected_age/life), color = 'black') +
  # geom_point(aes(y = remaining_life), color = 'black') +
  # geom_point(aes(y = elected_age), color = 'orange') +
  clean_plot

# graphing two variables
ggplot(data = pres3, aes(x = life, y = elected_age)) +
  geom_point(color = 'slateblue1') +
  stat_smooth(method = 'lm', formula = y ~ x, color = 'orange') +
  clean_plot


# graphing presidents over decades
ggplot() +
  geom_bar(data = decades, aes(x = time, weight = alive), alpha = .5, fill = 'orange') +
  geom_line(data = terms, aes(x = time, y = term), color = 'slateblue1', size = 2) +
  labs(x = 'Decades', y = 'Number of Presidents', title = 'Number of Presidents Alive Each Decade') +
  clean_plot


# graphing terms over time
ggplot(data = terms) +
  geom_line(aes(x = time, y = term)) +
  clean_plot


# reforming data for presidential life lines 
pres4 = pres3[complete.cases(pres3),]
pres4 = pres4[order(pres4$first_elected),]
pres4$id = seq.int(1,nrow(pres4))

# graphing presidents' life lines
ggplot(data = pres4, aes(x = first_elected, y = id)) +
  geom_vline(xintercept = seq(1730,1770,10), alpha = .2) +
  geom_vline(xintercept = seq(1780,2010,10), alpha = .5) +
  geom_point(color = 'slateblue1') +
  geom_segment(aes(x = shortBirth, xend = first_elected, yend = id), alpha = .4, color = 'orange') +
  geom_segment(aes(xend = first_elected+remaining_life, yend = id), color = 'orange') +
  labs(x = 'Time', y = 'Presidential Order', title = 'Presidential Life Lines') +
  clean_plot

# graphing the zodiacs of presidents
ggplot(data = zodiac) +
  geom_bar(aes(x = sign, weight = count), alpha = .5, fill = 'blue') +
  labs(x = 'Zodiac Sign', y = 'Count', title = 'Presidential Zodiac Signs') +
  clean_plot


# correlations
fit1 = lm(elected_age ~ life, data = pres3)
# summary(fit1)
# summary(fit1)$adj.r.squared



##### CONCLUSIONS #####

# Time vs Life : expected outcome to increase over time, but it's fairly scattered.
# This could be from not enough data to see this general trend, or that I'm just misinterpreting
# this trend (avearge life expectancy may have been stable during this time). When I looked it up,
# it appears that a couple things are happening. Data going back to 1850s (in England) shows life
# expectancy of a new born and a 5 year old both increasing over time. We are actually getting better
# at living longer. We also see the survival gap between a newborn and a 5 year old decrease to almost
# nothing in modern times, as infant mortality decreases considerably. It appears both trends are
# true. One hypothesis is that presidents are not a good sample of the general population. They tend
# to be (with few exceptions), rich, old, white men. As we see in the graph on this wonderful website
# (https://ourworldindata.org/life-expectancy/), life expectancy once you've made it to past 40-50, has
# really only increased in the last 50 years. Another hypothesis is that with more wealth, the more health
# care you can afford.

# Time vs Age in Life Elected : expected outcome unknown! Maybe initially older and getting younger
# because it's easier to become publicly known now. Back then, you'd take time to build reputation.
# However, there's no trend here, it's equally scattered.

# Age Elected vs Life : expected outcome to increase as people would wait until they were older to
# run for office. If you were going to die at 50, run at 35, not 45. There is a correlation here!
# It's a weak correlation, but significant.

# One Terms or Two(+) Terms : expected outcome to increase over time, with FDR at a peak. Reality
# demonstrates that there being several points with early departures in the mid-1800s and a string of 
# one term presidents, but no significant overarching trend. 

# Number of Presidents Alive Over Time : expected outcome to be same as Reddit, and we find it to be
# the same as Reddit! Life expectancy doesn't seem to play a big role here. It could be that there are
# more one term presidents earlier, and two term presidents reduce the number of presidents in play.
# FDR must have killed off many presidents during his tenure.


##### PIPING DATA TO RMARKDOWN ####

# I haven't quite got the hang of RMarkdown yet, and got caught with data/code in an R file, with all the 
# graphs, analysis, and formatting in the Rmd file. I'm exporting the data to be picked up by the markdown
# and used quickly. I'll figure out a better way before starting the next project.

# write.csv(p1, 'DataForMD/p1.csv')
# write.csv(p2, 'DataForMD/p2.csv')
# write.csv(pres3, 'DataForMD/pres3.csv')
# write.csv(decades, 'DataForMD/decades.csv')
# write.csv(pres4, 'DataForMD/pres4.csv')
# write.csv(zodiac, 'DataForMD/zodiac.csv')
# write.csv(summary(fit1)$adj.r.squared, 'DataForMD/fit1.csv')
