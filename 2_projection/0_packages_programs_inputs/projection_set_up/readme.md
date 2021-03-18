## Overview

Files in this folder are used by codes that generate projection configuration and csvv files. 
- `csvv_generation_stacked.do` is used to write csvv files. It contains programs that convert regression coefficients stored in stata `.ster` files into the csvv files that our projection system understands. 
  - Note - this csvv writer depends on the paths in this repo. If you are trying to write a csvv outside of this repo, you will need to edit it. 
  - The csvv writer is set up to write two kinds of csvvs:
    - `TINV_clim` which is the main model in the paper (See Methods, Appendix Section C.3). 
    - `TINV_clim_lininter` which is the model with a linear time interaction presented in the paper (See Appendix Section I.3). 
    - Note - the `TINV_clim_lininter_double` and `TINV_clim_lininter_half` model (Appendix Section I.3) uses the same csvv as the `TINV_clim_lininter` model. This is because they use the same regression specification and coefficients. We just specify that we deterministically double the time trend in the run configuration file. 
    - The  `slow_adapt` scenario presented in Appendix Section I.1 uses the same csvv as main model (`TINV_clim`). Similarly, this is because this model uses the same coefficients as the main model - we just deterministically halve the adaptation in the configuration file when running the projection.

- `projection_specifications.csv` is used to keep track of the coefficient names used by each model. 
  - If you are adding a new model to the csvv writer, you should add the model name and the related coefficient names to this csv file.
  - The csvv writer reads this csv, and uses it to determine which variables should be included.
  
- `write_projection_file.do` writes config files used by the projection system. See the readme in `2_projection/1_prepare_projection_files` for more details on the configs that are created. 


# Note for Ashwin and Rae - to be deleted: 
  - Note, these configs are currently generated in the way that we used them to run the projections. They point to csvv files, data, and configs on the CIL servers. 
They also depend on the name of the models that we used when we ran the projections initially. 
  - If you are running a new projection, with the model naming convention used in this repo, then you will need to update some of the logic in this code (eg to make some of the logic not dependent on the model name including the string "income_spline", since all of the models in the paper have an income spline, but we did not contain that string in the names of the models in this repo).
