# 3D Foot and Ankle Radiographic Measurements Toolbox

Use this toolbox to automatically calculate 2D radiographic measurements using 3D bone models in the foot and ankle.

## Description

This code takes a bone model as an input (tibia, fibula, talus, calcaneus, navicular, cuboid, three cuneiforms, and the five metatarsals) and automatically calculates selected 2D radiographic measurements. The input file type currently supported is ".k", ".stl", ".particles", ".vtk", and ".ply"; and the output is an interactive figure displaying the ACS and an .xlsx file with all selected measurements.

![Figure_AllMeasurements](https://github.com/user-attachments/assets/b8b2772b-51b1-46f4-99ec-8bab39b3f333)

## Getting Started

### Dependencies

If you want to run it in MATLAB:
* MATLAB R2020B or later
* Robotics System Toolbox
* Phased Array System Toolbox

### Executing program

If you want to run it in MATLAB:
* Pull the main repository
* Execute the Matlab script 'Main_FARM.m'
* Select the folder where the bone models are located
* It is recommended to have the bone name and laterality in each file name, but it isn't necessary
* If the file name does not contain the name of the bone and/or the laterally, you will need to manually select both of those for each bone

## Authors

* Andrew Peterson ([Github](https://github.com/AndrewCPeters0n), [Twitter](https://twitter.com/AndrewCPeters0n), andrew.c.peterson@utah.edu)

## Version History

* 0.1
    * Initial Release

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND).

## Acknowledgments

Funding for this project was provided by the NIH (K01 AR080221).

