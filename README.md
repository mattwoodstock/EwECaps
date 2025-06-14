# EwECaps
A repository that takes Ecopath with Ecosim with Ecospace output and calculates the ecosystem caps for the system under various types of calculations. The current example is from the Gulf of America Ecospace model.

The repository has two R files: functions.R and caps_from_ewe.R. To run, open the R project ("Ecosystem Caps") and the caps_from_ewe.R file. This file will automatically source the functions.R file. There are 4 dependencies: dplyr, tidyr, ggplot2, stringr. The code is designed to be run straight through. The user must manually input several items to properly run the file (shown below). It is recommended that the user make the adjustments and the run the full file so the final table is appropriately output without duplicate information.


**Manual Intervention Items**
1) L6: A group info table that has the following structure, where Residency determines if the animal is resident or not, SEDAR determines if the animal is a SEDAR assessed species, and Landings_Prop is the proportion of catches that are landings, since Ecospace_Annual_Average_Catch.csv is both landings and dead discards. This can be adjusted in anyway you need to slice your groups. You would just need to give an appropriate dataframe to the "keep_df" parameter in the "ecosystem_caps_avg...()" function. An example of adding a subset df to those functions can be seen in lines 93 & 99 of the main R file.

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


**Example Plots**
*This production function fit well*
![Good Plot](output/All%20Species%20with%20Bycatch/Spanish%20Mackerel.png)


*This production function did not fit well and the MSY was derived from both an average ASP and landings*
![Bad Plot](output/All%20Species%20with%20Bycatch/Reef%20invertebrate%20feeders.png)


**Final Result Table**
[Click to view CSV](https://github.com/mattwoodstock/EwECaps/blob/main/All%20Scenario%20Data.csv)

|Type              |Scenario                             |     BMSY|      MSY|  MSY_BMSY|  Prop_MSY| Prop_BMSY| |:-----------------|:------------------------------------|--------:|--------:|---------:|---------:|---------:| |All Species       |Landings and Discards - Avg. ASP     | 66232880| 696232.2| 0.0105119| 0.9655596| 0.0450564| |All Species       |Landings and Discards - Avg. Harvest | 66181366| 697028.8| 0.0105321| 0.9644561| 0.0450914| |Harvested Species |Landings and Discards - Avg. ASP     |  6946543| 649263.6| 0.0934657| 0.9934190| 0.3439321| |Harvested Species |Landings and Discards - Avg. Catch   |  6987793| 669765.9| 0.0958480| 0.9630093| 0.3419018| |SEDAR Species     |Landings and Discards - Avg. ASP     |  1484211| 505194.4| 0.3403790| 0.9982705| 0.9965861| |SEDAR Species     |Landings and Discards - Avg. Catch   |  1484234| 505180.6| 0.3403645| 0.9982978| 0.9965707| |Resident Species  |Landings and Discards - Avg. ASP     | 66101601| 674752.2| 0.0102078| 0.9641046| 0.0432751| |Resident Species  |Landings and Discards - Avg. Catch   | 66041400| 675306.9| 0.0102255| 0.9633128| 0.0433146| |All Species       |Landings Only - Avg. ASP             | 66186604| 678096.9| 0.0102452| 0.9664056| 0.0443847| |All Species       |Landings Only - Avg. Harvest         | 66134854| 678894.6| 0.0102653| 0.9652701| 0.0444194| |Harvested Species |Landings Only - Avg. ASP             |  6900267| 631128.3| 0.0914643| 0.9951284| 0.3394939| |Harvested Species |Landings Only - Avg. Catch           |  6941281| 651631.7| 0.0938777| 0.9638170| 0.3374879| |SEDAR Species     |Landings Only - Avg. ASP             |  1480389| 498508.7| 0.3367417| 0.9983906| 0.9963989| |SEDAR Species     |Landings Only - Avg. Catch           |  1480176| 498496.0| 0.3367815| 0.9984161| 0.9965423| |Resident Species  |Landings Only - Avg. ASP             | 66055263| 656870.1| 0.0099443| 0.9649516| 0.0426000| |Resident Species  |Landings Only - Avg. Catch           | 65994826| 657425.8| 0.0099618| 0.9641359| 0.0426390|
