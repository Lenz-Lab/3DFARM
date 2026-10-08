# 3D Foot and Ankle Radiographic Measurements Toolbox (3DFARM)

3DFARM calculates standard 2D radiographic foot and ankle measurements automatically from 3D bone models, such as segmentations of weightbearing CT. You provide the bones as `.stl` files and it returns up to 27 measurements in an Excel file, plus a figure for each measurement so you can check it.

![Figure_AllMeasurements](https://github.com/user-attachments/assets/b8b2772b-51b1-46f4-99ec-8bab39b3f333)

## Citation

Please cite this paper if you use this code in your work:

Peterson, A. C., Lapins, E. R., Requist, M. R., Kruger, K. M., Lenz, A. L. (2026). 3D foot and ankle radiographic measurement toolbox. Front. Bioeng. Biotechnol. 14:1892094. doi: 10.3389/fbioe.2026.1892094.

## Funding

This work is supported by the following grant:

[K01: Classification of Ankle Osteoarthritis Severity from Weightbearing Computed Tomography Using Statistical Shape Modeling and Machine Learning](https://reporter.nih.gov/search/QiRs1RF8o0WaXFlJt5tmBQ/project-details/11381842)

## Requirements

* MATLAB R2020b or later
* Statistics and Machine Learning Toolbox
* Optimization Toolbox
* Phased Array System Toolbox (for `rotx`, `roty`, `rotz` used in the alignment)

## Quick start

1. Clone or download this repository and open it in MATLAB.
2. Run `Main_FARM.m`.
3. Select `Demo_Data/FARM_Example.xlsx`, then choose a sheet.
4. Answer **No** to "Are you troubleshooting alignment?".

The measurements are written to `Demo_Data/Radiograph_Measurements_Demo_Data.xlsx`, with one sheet per subject.

## Preparing your data

### Bones

Each bone is a separate `.stl` file. The supported bones are the tibia, fibula, talus, calcaneus, navicular, cuboid, the three cuneiforms, the five metatarsals, the first and second proximal phalanges, and the two hallux sesamoids.

Include at least the **talus**, **calcaneus**, and **first metatarsal**. Together they define the foot coordinate system. The talus is needed for almost every measurement; the toolbox can run with the talus alone, but this is not recommended. See [Measurements](#measurements) for the bones each measurement needs.

### File names

The toolbox identifies each bone and its side from the file name, so a name like `ABC_01_Talus_Right.stl` needs no input from you. If it can't tell, it asks you to pick the bone and side for that file.

| Bone | Recognized names (any case) |
|---|---|
| Talus | `Talus` |
| Calcaneus | `Calcaneus`, `Calc` |
| Navicular, Cuboid | `Navicular`, `Cuboid` |
| Cuneiforms | `Medial_Cuneiform`, `Med_Cuneiform` (likewise `Intermediate`/`Int`, `Lateral`/`Lat`) |
| Metatarsals 1-5 | `Metatarsal1`, `Metatarsal_1`, `First_Metatarsal`, `1st_Met` (likewise for 2-5) |
| Tibia, Fibula | `Tibia`, `Fibula` |
| Proximal phalanges 1-2 | `Proximal_Phalanx1`, `Proximal_Phalanx_1`, `First_Proximal_Phalanx`, `1st_Proximal_Phalanx` (likewise for 2) |
| Medial sesamoid | `Medial_Sesamoid`, `Sesamoid1`, `Sesamoid_1` |
| Lateral sesamoid | `Lateral_Sesamoid`, `Sesamoid2`, `Sesamoid_2` |

The side is read from `Right`/`Left` or `_R_`/`_L_` (also `_R.`, `_R`, etc.) in the file name. If the file name doesn't give it, the column header in the FARM sheet is checked.

Avoid spaces in folder names.

### FARM sheet

The FARM sheet is an Excel file listing the bones for each subject, with one column per subject (see `Demo_Data/FARM_Example.xlsx`):

| CNO_08_L | CNO_08_R |
|---|---|
| CNO_08_L\CNO_08_left_calcaneus.stl | CNO_08_R\CNO_08_Tibia_Right.stl |
| CNO_08_L\CNO_08_left_cuboid.stl | CNO_08_R\CNO_08_Talus_Right.stl |
| ... | ... |

* Row 1 is the subject name. It is used as the output sheet name, shortened to 31 characters.
* The remaining rows are the `.stl` files, as paths relative to the folder containing the FARM sheet. Columns can have different lengths.
* If the workbook has more than one sheet, you are asked which one to process.

## Running

Run `Main_FARM.m` and select your FARM sheet. You are then asked **"Are you troubleshooting alignment?"**:

* **No** (default): the bones are aligned to the templates automatically.
* **Yes**: you are shown the bones and asked which anatomical direction the highlighted regions face, and the automatic alignment starts from your answer. Use this if the measurement figures show a subject aligned incorrectly.

Processing then runs subject by subject. A figure opens for each measurement showing the bones, the axes or landmarks used, and the value, so you can check every result visually.

## Output

`Radiograph_Measurements_<folder>.xlsx` is written to the folder containing the FARM sheet, where `<folder>` is that folder's name. It has one sheet per subject and one row per measurement, in the order listed below. A measurement whose bones were not provided is `NaN`.

## Measurements

Units are degrees unless noted. The view is the radiographic view each measurement corresponds to. Every measurement except the sagittal tibiocalcaneal angle also needs the talus.

| Measurement | View | Bones needed (plus talus) |
|---|---|---|
| Talocalcaneal Angle (Sagittal) | Lateral | Calcaneus |
| Talocalcaneal Angle (Axial) | AP foot | Calcaneus |
| Calcaneal Inclination Angle | Lateral | Calcaneus |
| Talar Tilt Angle | AP ankle | Tibia |
| Hindfoot Alignment Angle | Hindfoot alignment | Calcaneus, tibia |
| 20 deg Hindfoot Alignment Angle | Hindfoot alignment, 20° tilt | Calcaneus, tibia |
| Hindfoot Moment Arm (mm) | Hindfoot alignment | Calcaneus, tibia |
| Medial Distal Tibial Angle | AP ankle | Tibia |
| Tibial Lateral Surface Angle | Lateral | Tibia |
| Talonavicular Offset Angle (Axial) | AP foot | — |
| Meary's Angle (Axial) | AP foot | First metatarsal |
| Meary's Angle (Sagittal) | Lateral | First metatarsal |
| Talonavicular Angle | AP foot | Navicular |
| Foot Type Percentage (%) | AP foot | Calcaneus, first and fifth metatarsals |
| Intermetatarsal 1-2 | AP foot | First and second metatarsals |
| Calcaneal 1st Metatarsal Angle | Lateral | Calcaneus, first metatarsal |
| Tibiocalcaneal Angle (Sagittal) | Lateral | Tibia, calcaneus (talus not needed) |
| Tibiocalcaneal Angle (Axial) | AP foot | Tibia, calcaneus |
| Metatarsal Stacking Angle | Lateral | First and fifth metatarsals |
| Medial-Lateral Column Ratio (ratio) | — | Calcaneus, first and fifth metatarsals |
| Naviculocuboid Overlap (%) | Lateral | Navicular, cuboid |
| Hallux Valgus Angle | AP foot | First metatarsal, first proximal phalanx |
| MTP2 Valgus Angle | AP foot | Second metatarsal, second proximal phalanx |
| Sesamoid Rotation Angle | Sesamoid axial | First metatarsal, both sesamoids |
| Sesamoid Medial-Lateral Displacement (mm) | AP foot | First metatarsal, both sesamoids |
| Distal Metatarsal Articular Angle | AP foot | First metatarsal |
| Metatarsal 1 Pronation Angle | Sesamoid axial | First metatarsal |

### Notes on specific measurements

* **Hindfoot Moment Arm** and **Sesamoid Medial-Lateral Displacement** are positive when the point is medial to the reference axis.
* **Distal Metatarsal Articular Angle (DMAA)** is positive for lateral (valgus) deviation of the articular surface. The first metatarsal head is projected onto the AP plane, and the medial and lateral edges of the articular surface are taken as the corners of the head outline on either side of the distal tip. DMAA is the angle between the perpendicular to the line through those edges and the first metatarsal axis. On heads without clear corners an edge can be placed too far proximally, so check the DMAA figure.
* **Metatarsal 1 Pronation Angle** differed little between hallux valgus and control feet in testing; interpret it with caution.

## How it works

1. **Load:** each bone is read and identified from its file name.
2. **Prealign:** the bones are combined and aligned to a template foot of the same side with iterative closest point (ICP). Only bones that have a full foot template (all except the phalanges and sesamoids) drive this fit, and the result is applied to all bones.
3. **Coordinate systems:** each bone is aligned to its own template, and an anatomical coordinate system and landmarks are computed from it.
4. **Reference frames:** foot measurements use a foot frame averaged from the talus, calcaneus, and first metatarsal coordinate systems (the talus alone if those are missing). Ankle measurements use the tibia's frame.
5. **Measure:** each measurement is calculated in the plane of its radiographic view and written to Excel.

## Authors

* Andrew Peterson ([Github](https://github.com/AndrewCPeters0n), [Twitter](https://twitter.com/AndrewCPeters0n), andrew.c.peterson@utah.edu)

## Version History

* 1.1
    * Added the proximal phalanges and sesamoids, and the hallux measurements (HVA, MTP2 valgus, SRA, SMLD, DMAA, M1 pronation)
* 1.0
    * Initial release

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND).
