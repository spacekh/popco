


# experiment
plotFourDomainsV1 <- function(data, aggregFn, title.ignored) {
  # copied and modified from http://sphaerula.com/legacy/R/multiplePlotFigure.html
  ##  Open a new default device.
  getOption( "device" )()

  ##  Split the screen into two rows and one column, defining screens 1 and 2.
  split.screen( figs = c( 2, 1 ) )
  ##  Split screen 1 into one row and two columns, defining screens 3 and 4
  split.screen( figs = c( 1, 2 ), screen = 1 )
  ##  Split screen 2 into one row and two columns, defining screens 6 and 7.
  split.screen( figs = c( 1, 2 ), screen = 2 )

  screen( 3 )
  plotForDomain(data, "P", aggregFn)
  screen( 4 )
  plotForDomain(data, "H", aggregFn)
  screen( 5 )
  plotForDomain(data, "OE", aggregFn)
  screen( 6 )
  plotForDomain(data, "OS", aggregFn)
}


readcsvs(csvs) {
  dframes <- list()

  for (i in 1:length(csvs)) {
    dframes[[i]] <- read.csv(csvs[i])
  }

  dframes
}

ra2domra <- function(ra, dom) {
  propnames = dimnames(ra)[2][[1]] # get the proposition names from the ra
  regx = paste0("^", dom, ".")     # we'll search for this string
  colnums = grep(regx, propnames)  # get indexes of columns we want
  ra[ , colnums , ]  # return an array with only columns we want
}
