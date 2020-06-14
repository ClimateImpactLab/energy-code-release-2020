## Post projection analysis

#### Contents: 
- SCC code. This code takes in damage function coefficients estmiated previously, and outputs SCC values. 
- `/Functions/`: this folder contains some FAIR parameters and functions used by the SCC code.  

#### Run Instructions
This code requires a Python 2.7 environment, with certain packages installed. It can be run from inside a conda environment, after creating a conda environment using the following command: 

```
conda create -n scc_env python=2.7 numpy pandas xarray matplotlib seaborn jupyter NetCDF4
conda activate scc_env
jupyter notebook {path_to_this_repo}/energy-scc-code-2020-release.ipynb
```

Then run the jupyter notebook from inside this conda environment. 

You will also need to change the `root` variable so that it points to the location of the energy-code-release-2020 repo on your machine, and the `DB` variable so that it points to the location of the data storage directory.

There are details of the calculations done in this code in Appendix F of the paper, and in comments inside the code itself. 
