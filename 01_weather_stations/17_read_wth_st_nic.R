# Created by: Lizeth Llanos l.llanos@cgiar.org
# This script read html files for Nicaragua stations 
# Date: May 2018

library(RCurl)
library(XML)
library(dplyr)
library(tidyr)

htmlToText <- function(input, ...) {
  ###---PACKAGES ---###
  require(RCurl)
  require(XML)
  
  
  ###--- LOCAL FUNCTIONS ---###
  # Determine how to grab html for a single input element
  evaluate_input <- function(input) {    
    # if input is a .html file
    if(file.exists(input)) {
      char.vec <- readLines(input, warn = FALSE)
      return(paste(char.vec, collapse = ""))
    }
    
    # if input is html text
    if(grepl("</html>", input, fixed = TRUE)) return(input)
    
    # if input is a URL, probably should use a regex here instead?
    if(!grepl(" ", input)) {
      # downolad SSL certificate in case of https problem
      if(!file.exists("cacert.perm")) download.file(url="http://curl.haxx.se/ca/cacert.pem", destfile="cacert.perm")
      return(getURL(input, followlocation = TRUE, cainfo = "cacert.perm"))
    }
    
    # return NULL if none of the conditions above apply
    return(NULL)
  }
  
  # convert HTML to plain text
  convert_html_to_text <- function(html) {
    doc <- htmlParse(html, asText = TRUE)
    text <- xpathSApply(doc, "//text()[not(ancestor::script)][not(ancestor::style)][not(ancestor::noscript)][not(ancestor::form)]", xmlValue)
    return(text)
  }
  
  # format text vector into one character string
  collapse_text <- function(txt) {
    return(paste(txt, collapse = " "))
  }
  
  ###--- MAIN ---###
  # STEP 1: Evaluate input
  html.list <- lapply(input, evaluate_input)
  
  # STEP 2: Extract text from HTML
  text.list <- lapply(html.list, convert_html_to_text)
  
  # STEP 3: Return text
  text.vector <- sapply(text.list, collapse_text)
  return(text.vector)
}

# Run function to read html files
files <- "C:/Users/lllanos/Downloads/45005 Quilali 1958.htm"

html_files <- files %>% htmlToText %>% strsplit(., split = " ") %>% unlist %>% .[.!=""]
pos_sum <- which(html_files=="Suma")

data_end <- matrix(html_files[(pos_sum[1]+1):(pos_sum[2]-1)],31,14, byrow = T, dimnames = list(1:31,c("day",month.abb,"sume"))) %>% 
            as.data.frame(.) %>% .[,-ncol(.)] %>%  gather(key = month, value = value,-day)

info_cat <- html_files[1:pos_sum[1]]