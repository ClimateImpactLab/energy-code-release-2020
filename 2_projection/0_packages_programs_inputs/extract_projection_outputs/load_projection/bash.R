#' ---
#' Purpose:  ${1: Functions for interfacing with shell scripts from R script}
#' authors: ${2: Maya Norman and Tom Bearpark}
#' date:   ${3:`date +%Y-%m-%d`}
#' 
#' Functions:
#'  call.shell.script - Calls extraction shell script
#'  check.memory - Kills process if there isn't enough available memory for the process to keep running
#'  get.available.memory - Get available memory for use
#'  get.process.memory.use - Get process memory use (in percent of total memory)
#'  get.bash.parameters - Gets parameters ready for use in call.shell.script. Along the way, function 
#'   checks to make sure parameter values are within the functionality of the extraction shell
#'   and required parameters have non-null non-blank values
#'  extract - Perform extraction while monitoring memory use 
#'  check.file.complete - Check to see if a file is complete based on time last touched

library(DescTools)
library(stringr)
library(testit)
library(glue)
library(sys)
library(R.utils)
squish_function <- stringr::str_squish


#' Perform extraction while monitoring memory use 
#' 
#' @param paths paths to all relevant files
#' @inheritParams
#' @export
#'

extract <- function(paths = list(), ...) {
    
    kwargs = list(...)
    kwargs = rlist::list.append(kwargs, shell.file = paths$shell_path, extract = 'true')
    parameters = do.call(get.bash.parameters, kwargs)
    
    kwargs = rlist::list.append(kwargs, parameters = parameters)
    output.text = do.call(call.shell.script, kwargs)
    
    print(output.text)
    
    pid = as.numeric(get.line.var(var = 'pid', definer = ':', line = output.text[grepl('pid', output.text)]))

    ptm <- proc.time()

    # provide extraction updates until file desired file is in progress
    while (!file.exists(paths$file)) {
      
      Sys.sleep(30)
      print('quantiles.py status:')
      system(paste0('tail ', paths$log.file))
      
      # kill job if not enough available memory
      check.memory(pid = pid)
    }

    # wait until function isn't being worked on anymore
    print('Waiting for process to finish working on file...')
    check.file.complete(file = paths$file)

    print('Extraction time consumption stats:')
    print(proc.time() - ptm)
    print('Extraction complete.')
}

#' Check to see if a file is complete based on time last touched
#' 
#' @param file file getting queried
#' @inheritParams
#' @export
#'

check.file.complete <- function(file = '', ...) {
    
    # organize environment and get code paths
    kwargs = list(...)

    get.diff <- function(file = '') {
      last.touched = as.POSIXct(system(glue::glue("stat -c %y {file}"), intern = TRUE))
      current.time = Sys.time()
      diff = difftime(current.time, last.touched, units = 'secs')[[1]]
      return(diff)
    }

    diff = get.diff(file = file)
    
    while(diff < 10) {
      print('Still not done. The file is writing away...')
      print(glue::glue('{file} was last worked on {diff} seconds ago.'))
      Sys.sleep(10)
      diff = get.diff(file = file)
    }  
}


#' Calls extraction shell script
#' 
#' @param shell.file /path/to/extraction/shell/script.sh
#' @param parameters parameters to be passed to shell script
#' @inheritParams
#' @return list with the text output from the bash script and the script's pid
#' @export
#'

call.shell.script <- function(shell.file = '', parameters = '', ...) {
    
    # organize environment and get code paths
    kwargs = list(...)

    print('Calling Extraction Shell...')
    print(glue::glue('parameters feeding script: {parameters}'))
    
    command = paste0("bash ",shell.file, " ", '"', parameters,'"')
    print("#########################################################")
    print(command)

    output.text = system(command, intern = TRUE)
    
    if (all(grepl("Abort", output.text))) {
      print(output.text)
      stop("Abort statement revisit parameter values.")
    }

    return(output.text)
}

#' Kills process if there isn't enough available memory for the process to keep running
#' 
#' @param pid pid identifier for a process
#' @param cmnd.id distinct word in command for process
#' @inheritParams
#' @export
#'

check.memory <- function(pid = NULL, cmnd.id = 'python') {
  
  mem.avail = get.available.memory() 
  mem.use = get.process.memory.use(pid = pid, cmnd.id = cmnd.id)

  if (mem.avail < 40) {
      print('Memory exploding or not enough memory available to complete job...')
      tools::pskill(pid)
      stop('Killed extraction process. Monitor process on htop to see memory constraint issues')
  }

}

#' Get available memory for use
#' 
#' @inheritParams
#' @export
#' @return memory available for use
#'

get.available.memory <- function(...) {
  
  print("Fetching available memory (GB)...")
  mem.avail.string = system("free -h | awk '{print $7}'", intern=TRUE)[2]
  mem.avail = as.numeric(gsub('Gi', '', mem.avail.string)) # always want some buffer
  print(mem.avail)
  return(mem.avail)

}

#' Get process memory use
#' 
#' @param pid pid for process
#' @param cmnd.id distinct word in command for process
#' @inheritParams
#' @export
#' @return percent total memory getting used by process
#'

get.process.memory.use <- function(pid = NULL, cmnd.id = '') {
  
  print(glue::glue("Fetching pid {pid} percent memory use..."))
  
  print.statement = '{print "command:"$4 " %memory:"$3}'
  mem.use = system(glue::glue("ps -o pid,user,%mem,command ax | grep {pid} | awk '{print.statement}'"), intern = TRUE)
  mem.use = mem.use[grepl(cmnd.id, mem.use)]
  mem.use = as.numeric(substr(mem.use, DescTools::StrPos(mem.use, "%memory:", pos=1) + nchar("%memory:"), nchar(mem.use)))
  print(mem.use)
  return(mem.use)
}

#' Takes parameter values and shell.file (passed through ...) 
#' and returns parameters ready for use in shell script calling. Along the way, function 
#' checks to make sure parameter values are within the functionality of the extraction shell
#' and required parameters have non-null non-blank values
#' 
#' @inheritParams
#' @return string of parameters ready to be called in the command line
#' @export
#'

get.bash.parameters <- function(...) {
    
    kwargs = list(...)

    print("Retrieving shell script parameter information...")
    possible.parameters = do.call(get.shell.file.parameters, kwargs)

    parameters = ''

    print("Creating list of parameters to pass to shell file...")
    for (parameter in names(possible.parameters)) {

      print(glue::glue('adding parameter {parameter} to the list of parameters...'))

      # currently this function is specific to energy's extraction shell script
      testit::assert(c('options', 'required') %in% names(possible.parameters[[parameter]]))
      
      # check parameter falls in bounds of possibilities

        parameter.not.blank = !is.null(kwargs[[parameter]]) && kwargs[[parameter]] != ''
        parameter.defined = !("UNDEFINED" %in% possible.parameters[[parameter]][['options']])
        parameter.required = possible.parameters[[parameter]][['required']] == 'yes'

        if (parameter.required & parameter.defined) {
          # logic: if parameter defined and required, then parameter value must be in list of parameter value options
          testit::assert(kwargs[[parameter]] %in% possible.parameters[[parameter]][['options']] )
        } else if (parameter.required & !(parameter.defined)) {
          # logic: if parameter required but undefined, then parameter must have a value
          if (parameter.not.blank != TRUE) {
            stop(glue::glue("Must include a {parameter} value in arguments!"))
          }
        } else if (parameter.defined & parameter.not.blank) { 
          # logic: if parameter not required but defined and not blank then make sure parameter value is one of the prespecified options
          testit::assert(kwargs[[parameter]] %in% possible.parameters[[parameter]][['options']] )
        }
      
      # add parameter to list of parameters for the command line
      
        param.name = paste0(parameter,"=")
        param.value = paste0(kwargs[[parameter]],";")
        parameters = paste0(parameters, param.name, param.value)

    }

    return(parameters)
}
