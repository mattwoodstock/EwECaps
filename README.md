# EwECaps
A repository that takes Ecopath with Ecosim with Ecospace output and calculates the ecosystem caps for the system under various types of calculations. The current example is from the Gulf of America Ecospace model.

The repository has two R files: functions.R and caps_from_ewe.R. To run, open the R project ("Ecosystem Caps") and the caps_from_ewe.R file. This file will automatically source the functions.R file. There are 4 dependencies: dplyr, tidyr, ggplot2, stringr. The code is designed to be run straight through. The user must manually input several items to properly run the file (shown below). It is recommended that the user make the adjustments and the run the full file so the final table is appropriately output without duplicate information.

*Manual Intervention Items*
1) L6: A group info table that has the following structure, where Residency determines if the animal is resident or not, SEDAR determines if the animal is a SEDAR assessed species, and Landings_Prop is the proportion of catches that are landings, since Ecospace_Annual_Average_Catch.csv is both landings and dead discards.

| Group_Name             | Residency | SEDAR | Landings_Prop |
|------------------------|-----------|-------|----------------|
| Blacktip shark         | Resident  | SEDAR | 0.609          |
| Dusky shark            | Resident  | SEDAR | 0.979          |
| Sandbar shark          | Resident  | NO    | 0.561          |
| Large coastal sharks   | Resident  | SEDAR | 0.490          |
| Large oceanic sharks   | Transient | NO    | 1.000          |

2) L17-21: Incoporate your model's specific characteristics (start_year, model domain area in km, Ecospace scenario name).
3) L30: Adjust the group names to aggregate the relevant multi-stanza groups in your model. We want to aggregate multi-stanza groups to create a single cap per species.
4) L73 & 173: After plotting (L68 & 170), the user should check the plots and identify those that could not be fit properly (i.e., linear ASPt - Bt relationship, negative [u-shaped] parabolic function, negative predicted BMSY).
