# 3D Foot and Ankle Radiographic Measurements Toolbox

Use this toolbox to automatically calculate 2D radiographic measurements using 3D bone models in the foot and ankle.

## Publications
Please cite this paper if you use this code in your work:

Peterson, A. C., Lapins, E. R., Requist, M. R., Kruger, K. M., Lenz, A. L. (2026). 3D foot and ankle radiographic measurement toolbox. Front. Bioeng. Biotechnol. 14:1892094. doi: 10.3389/fbioe.2026.1892094.

## Funding
This work is supported by the following grant:

[K01: Classification of Ankle Osteoarthritis Severity from Weightbearing Computed Tomography Using Statistical Shape Modeling and Machine Learning](https://reporter.nih.gov/search/QiRs1RF8o0WaXFlJt5tmBQ/project-details/11381842)

## Description

This code takes a bone model as an input (tibia, fibula, talus, calcaneus, navicular, cuboid, three cuneiforms, the five metatarsals, the first and second proximal phalanges, and the two hallux sesamoids) and automatically calculates selected 2D radiographic measurements. The input file type currently supported is ".stl"; and the output is an interactive figure displaying the ACS and an .xlsx file with all selected measurements.

For best results, include at least the **talus**, **calcaneus**, and the **first metatarsal**. It can run with just the talus, but it is not recommended.

### Hallux measurements

| Measurement | Bones required |
|---|---|
| Hallux Valgus Angle | First metatarsal, first proximal phalanx |
| MTP2 Valgus Angle | Second metatarsal, second proximal phalanx |
| Sesamoid Rotation Angle | First metatarsal, both sesamoids |
| Sesamoid Medial-Lateral Displacement | First metatarsal, both sesamoids |
| Distal Metatarsal Articular Angle (DMAA) | First metatarsal |
| Metatarsal 1 Pronation Angle | First metatarsal |

Name the hallux bones with `Proximal_Phalanx1`, `Proximal_Phalanx2`, `Sesamoid1` (medial), and `Sesamoid2` (lateral), or `Medial_Sesamoid` and `Lateral_Sesamoid`.

DMAA is measured in the axial plane, comparable to an AP radiograph. The first metatarsal head is projected onto that plane and the medial and lateral edges of the articular surface are taken as the corners of the head outline on either side of the distal tip. DMAA is the angle between the perpendicular to the line through those edges and the first metatarsal axis (positive = valgus). Check the DMAA figure for each subject: on heads without clear corners an edge can be placed too far proximally.

![Figure_AllMeasurements](https://github.com/user-attachments/assets/b8b2772b-51b1-46f4-99ec-8bab39b3f333)

## Getting Started

### Dependencies

If you want to run it in MATLAB:
* MATLAB R2020B or later
* Statistics and Machine Learning Toolbox
* Optimization Toolbox

### Executing program

If you want to run it in MATLAB:
* Pull the main repository
* Execute the Matlab script 'Main_FARM.m'
* Select the excel file with your desired bones (see Demo_Data/FARM_Example.xlsx)
* It is recommended to have the bone name and laterality in each file name, but it isn't necessary
* If the file name does not contain the name of the bone and/or the laterally, you will need to manually select both of those for each bone

## Authors

* Andrew Peterson ([Github](https://github.com/AndrewCPeters0n), [Twitter](https://twitter.com/AndrewCPeters0n), andrew.c.peterson@utah.edu)

## Version History

* 1.1
    * Added proximal phalanges and sesamoids, and hallux measurements (HVA, MTP2 valgus, SRA, SMLD, DMAA, M1 pronation)
* 1.0
    * Initial Release

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND).

