#' ---
#' Purpose:  ${1: Functions for parsing config and shell scripts for use in load_projection}
#' authors: ${2: Maya Norman and Tom Bearpark}
#' date:   ${3:`date +%Y-%m-%d`}
#'
#' Functions:
#'  get.line.var - Get specific variable's value from a string
#'  get.file.var - Scroll through all lines of a file and get value of a specific variable defined at some point in the file
#'  get.shell.file.parameters - Get list of parameters that need to be defined when calling extraction bash script as well 
#'   as information about that parameter
#'  parse.config.structure - Convert the file-structure parameter in an extraction config into the file prefix outputed when a specific
#'   file-structure value is used
#' 


library(DescTools)
library(stringr)
library(testit)
library(rlist)
library(glue)
squish_function <- stringr::str_squish

#' Get specific variable's value from a string
#' 
#' @param var name of variable getting value for
#' @param definer symbol used to assign value to var
#' @param line line of text parsing
#' @inheritParams
#' @return value of variable assigned in line using the definer
#' @export
#' 

get.line.var <- function(var = '', definer = '', line = '') {
  
  definer.position = DescTools::StrPos(line, definer, pos = 1) - 1
  value = ''
  if (!is.na(definer.position)) {
    if (substr(line,1,definer.position) == var) {
      value = trimws(substr(line, definer.position + 2, nchar(line)))
    }
  }
  return(value)
}

#' Scroll through all lines of a file and get value of a specific variable defined at some point in the file 
#' Note: var can only be assigned once in file or else only first var definition will be returned
#' 
#' @param var name of variable getting value for
#' @param file text file or code looking for variable definition in
#' @inheritParams
#' @return value of variable assigned in line using the definer
#' @export
#'

get.file.var <- function(var = '', file = '', ...) {
  
  # Var is one of the variables defined in the file of interest. eg "results-root"
  # file is the full path and name of the yml/or  you want to read 
  
  value = ''

  if (grepl(".sh",file)) {
    definer = '='
  } else if (grepl(".yml",file)) {
    definer = ':'
  } else {
    stop('Must define a definer for file type.')
  }

  lines = squish_function(readLines(file))

  for (line in lines){
    value = get.line.var(var = var, definer = definer, line = line)
    if (value != '') {
      return(value)
    }
  }
}

#' Get list of parameters that need to be defined when calling extraction bash script as well as information about that parameter
#' 
#' @param definer.begin string variable seperating name of definition type and definition value
#' @param definer.sep string variable indicating two defintions are seperate entities
#' @param shell.file text file or code looking for parameter definition in
#' @inheritParams
#' @return possible.parameters (a dictionary of dictionary)
#' parameters=names(possible.parameters), [types of supporting information]=names(possible.parameters[[parameter]]), 
#' and [supporting info values] = possible.parameters[[parameter]][[type of supporting info]]
#' For example, possible.parameters[['conda_env']][['options']] == 'UNDEFINED' and possible.parameters[['conda_env']][['required']] == 'yes'
#' @export
#'

get.shell.file.parameters <- function(shell.file = '', definer.begin=':', definer.sep='/', ...) {
  
  lines = squish_function(readLines(shell.file))
  possible.parameters = list()

  for (ii in seq(lines)) {

    line = lines[[ii]]
    
    number.definers.begin = stringr::str_count(line, pattern = definer.begin)
    number.definers.end = stringr::str_count(line, pattern = definer.sep)

    # extract parameters and their options from lines with parameter definitions in shell script
    if (number.definers.begin > 0 & number.definers.end > 0) {
      
      print('Line getting parsed:')
      print(line)

      # set up lists to be populated
      value.list = list()
      name.list = list()

      # prepare line to be parsed
      line = substr(line, DescTools::StrPos(line, definer.sep, pos=1) + 2, nchar(line))
      
      for (ff in seq(1, number.definers.begin)) {
        
        # get positional parameters
        position.begin = DescTools::StrPos(line, definer.begin, pos=1)
        position.end = DescTools::StrPos(line, definer.sep, pos=1)
        
        # parse definer and its value
        definer = substr(line, 1, position.begin - 1)
        value = substr(line, position.begin + 1, position.end - 2)
        value = unlist(strsplit(value, split=", "))

        # append definer name and value to lists
        value.list = rlist::list.append(value.list, value)
        name.list = rlist::list.append(name.list, definer)

        # reduce line to extract next definer name and value
        line = substr(line, position.end + 2, nchar(line))
      }

      # assign definer names to value csv
      names(value.list) = name.list

      # append parameter name, its possible values and if the parameter is required to a dictionary with dictionaries
      # the key to the outer dictionary is the parameter name
      # the key to the inner dictionary is each other definer's name
      # assumes first definer in shell script line is the parameter name
      possible.parameters[[value.list[[1]]]] = value.list[2:length(value.list)]
    }
  }
  return(possible.parameters)
}

#' Convert the file-structure parameter in an extraction config into the file prefix outputed when a specific
#' file-structure value is used
#'  
#' @param region region desired in queried dataset
#' @param ssp ssp scenario
#' @param rcp rcp scenario
#' @param iam iam scenario
#' @param structure the file structure parameter defined in extraction configs
#' @inheritParams
#' @return possible.parameters (a dictionary of dictionary)
#' parameters=names(possible.parameters), [types of supporting information]=names(possible.parameters[[parameter]]), 
#' and [supporting info values] = possible.parameters[[parameter]][[type of supporting info]]
#' For example, possible.parameters[['conda_env']][['options']] == 'UNDEFINED' and possible.parameters[['conda_env']][['required']] == 'yes'
#' @export
#'

parse.config.structure <- function(structure = '', region = NULL, ssp = '', rcp = NULL, iam = NULL, ...) {
  
  print(glue::glue('Converting {structure} to a file prefix...'))
  st = gsub("\\[|\\]", "", structure)
  st.list = unlist(strsplit(st, split=", "))
  gg.prefix = ''
  # browser()
  if (!is.null(region)) {
    if (grepl('region', structure) && region == "global")  {
      region = ''
    }
  } 

  for (ii in seq(st.list)) {
    gg = paste0('{', st.list[ii],'}')
    gg.prefix = paste0(gg.prefix,gg,'-')
  }

  prefix = glue::glue(substr(gg.prefix, 1, nchar(gg.prefix) - 1))
  return(prefix)
}



