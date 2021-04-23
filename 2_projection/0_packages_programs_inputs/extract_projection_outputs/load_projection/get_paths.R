#' ---
#' Purpose:  ${1: Functions for getting desired paths and file names from query}
#' authors: ${2: Maya Norman and Tom Bearpark}
#' date:   ${3:`date +%Y-%m-%d`}
#' 
#' Functions: 
#'  get.energy.code.paths - Get code paths for relevant objects throughout laod_projection
#'  get.file.paths - Get relevant file paths for querying data
#'  get.paths - Get relevant code and file paths 
#'

library(DescTools)
library(stringr)
library(testit)
library(glue)
squish_function <- stringr::str_squish


#' Get energy specific code paths for relevant objects throughout laod_projection
#' this funciton is unnecessary i like it though... so it remains :D
#' 
#' @inheritParams
#' @return list of paths to relevant code
#' @export
#' 

get.energy.code.paths <- function(uncertainty = NULL,...) {

  kwargs = list(...)
  args = as.list(environment())
  gecn.args = append(kwargs,args)

  uname = Sys.getenv("LOGNAME")
  energy.repo = glue::glue('/home/{uname}/repos/energy-code-release-2020')
  
  # if energy.repo doesn't exist in the right place aborrt mission
  if (!dir.exists(energy.repo)){
    stop('You need to save the energy code release repo at /home/{your username}/repos. aborting mission. code wont execute properly')
  }

  # writing paths
  shell.path = glue::glue('{energy.repo}/2_projection/0_packages_programs_inputs/extract_projection_outputs/load_projection')
  
  if (uncertainty != 'single') {
  	extraction.shell.name = 'extraction_quantiles.sh'
  }

  return(list(
    shell_path = glue::glue('{shell.path}/{extraction.shell.name}')))
}

#' Get relevant file paths for querying data
#' 
#' @param code.paths list of paths to relevant pieces of code
#' @inheritParams
#' @return list of relevant files
#' @export
#' 

get.file.paths <- function(code.paths = list(), ...) {

  kwargs = list(...)

  kwargs = rlist::list.append(kwargs, shell.file = code.paths$shell_path, extract = 'false')

  # get paramters for calling shell script
  print('Fetching parameters for calling extraction bash script...')
  parameters = do.call(get.bash.parameters, kwargs)
  kwargs = rlist::list.append(kwargs, parameters = parameters)

  # Get file suffix, extraction config path, and log.file path 

  print("Calling extraction bash script to retrieve desired information...")
  output.text = do.call(call.shell.script, kwargs)

  print("Retrieving desired info from bash script output...")
  
  for(var in c('extraction.config', 'suffix', 'log.file')) {
  	line = output.text[grepl(var, output.text)]
  	value = get.line.var(var = var, definer = ':', line = line)
  	assign(paste(var), value)
  	rm(line, value)
  }


  # Read the useful lines from the config
  print(glue::glue("Fetching desired info from {extraction.config}..."))
  file.path <- get.file.var(var = "output-dir", file = extraction.config)
  structure <- get.file.var(var = "file-organize", file = extraction.config)

  print('Converting file structure to file prefix...')
  kwargs = rlist::list.append(kwargs, structure = structure)
  prefix = do.call(parse.config.structure, kwargs)

  # If the output folder doesn't exist - lets make it
  if (!dir.exists(file.path(file.path))) {
    dir.create(file.path(file.path))
  }

  file = paste0(file.path, "/", prefix, suffix, ".csv")
  print(paste0('querying: ', file))

  file.paths = list(file = file, log.file = log.file)
  return(file.paths)

}


#' Get relevant code and file paths 
#' 
#' @param code.getter a function which fetches a list of code paths
#' @inheritParams
#' @return list of relevant code and data paths
#' @export
#' 

get.paths <- function(code.path.getter = get.energy.code.paths, ...) {

	print('Getting relevant paths...')

	kwargs = list(...)
	kwargs = rlist::list.append(kwargs)
  	
  	print("Getting code paths...")
    code.paths = do.call(code.path.getter, kwargs)
    kwargs = rlist::list.append(kwargs, code.paths = code.paths)

    print("Getting file paths...")
    file.paths = do.call(get.file.paths, kwargs)
    print("file path is: ")
    print(file.paths)

    paths = append(code.paths, file.paths)
    return(paths)
}


