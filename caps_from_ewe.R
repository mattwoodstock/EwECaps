######################################################
##  Calculate Ecosystem Caps from Ecospace Output  ###
######################################################
source("functions.R")
## Parameters
group_info = readxl::read_xlsx("Groups.xlsx",sheet=1) #Read in .csv of group info

# Here is the head of my group_info file
#Group_Name               Residency SEDAR Landings_Prop
#<chr>                    <chr>     <chr>         <dbl>
#1 Blacktip shark           Resident  SEDAR        0.609 
#2 Dusky shark              Resident  SEDAR        0.979 
#3 Sandbar shark            Resident  NO           0.561 
#4 Large coastal sharks     Resident  SEDAR        0.490 
#5 Large oceanic sharks     Transient NO           1     

start_year = 1980 #Your model start year

area = 310000 #Area of domain

ecospace_scen = "EcospaceData" #The name of the Ecospace/Ecosim scenario.
#* Note that I do not output with headers. If doing that, we'll need to either adjust the load_ecospace_data function or rerun the model without.

## Load in Ecospace data ----
### Biomass

merged_df = load_ecospace_data(ecospace_scen)

### Merge necessary species (adjust to your multispecies stanza)
reduced_df <- merged_df %>%
  mutate(Group_Name = case_when(
    Group == "King mackerel (0-1yr)" ~ "King Mackerel",
    Group == "King mackerel (1+yr)" ~ "King Mackerel",
    Group == "Spanish mackerel (0-1yr)" ~ "Spanish Mackerel",
    Group == "Spanish mackerel (1+yr)" ~ "Spanish Mackerel",
    Group == "Gag grouper (0-3yr)" ~ "Gag Grouper",
    Group == "Gag grouper (3+yr)" ~ "Gag Grouper",
    Group == "Red grouper (0-3yr)" ~ "Red Grouper",
    Group == "Red grouper (3+yr)" ~ "Red Grouper",
    Group == "Yellowedge grouper (0-3yr)" ~ "Yellowedge Grouper",
    Group == "Yellowedge grouper (3+yr)" ~ "Yellowedge Grouper",
    Group == "Red snapper (0yr)" ~ "Red Snapper",
    Group == "Red snapper (1-2yr)" ~ "Red Snapper",
    Group == "Red snapper (3+yr)" ~ "Red Snapper",
    Group == "Menhaden (0yr)" ~ "Menhaden",
    Group == "Menhaden (1yr)" ~ "Menhaden",
    Group == "Menhaden (2yr)" ~ "Menhaden",
    Group == "Menhaden (3yr)" ~ "Menhaden",
    Group == "Menhaden (4yr)" ~ "Menhaden",
    TRUE ~ Group
  ))

## Initialize the result dataframe
all_scenario_data = data.frame(Type = character(),Scenario = character(),BMSY = numeric(),MSY = numeric(),MSY_BMSY = numeric(),Prop_MSY = numeric(),Prop_BMSY = numeric())

# Landings Only ----

## All species regardless of harvest ----
type = "All Species with Bycatch"

#Develop MSY models
result = develop_models(reduced_df)

models = result$models
asp_df = result$asp_df

#Plot MSYs (Need to run to get msy_values)
msy_values = plot_models(models,asp_df,type,scenario,to_plot=T) #Can turn plotting off by setting to_plot = F

type = "All Species" #Set this so that spreadsheets go to a similar location, but plots do not.

# Groups where the MSY curve did not provide a suitable curve or did not represent the data. Groups with no curve (no fitting model) are already included
poor_fits = c("Algae","Anchovy-silverside-killifish","Cephalopod","Detritus","Infauna","Mobile epifauna","Offshore dolphins","Phytoplankton","Reef omnivores","Sardine-herring-scad","Sessile epifauna","Zooplankton")

### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. ASP"

#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = asp_df)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. Harvest ----
scenario = "Landings and Discards - Avg. Harvest"

analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = asp_df)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

## Harvested Species Only ----
type = "Harvested Species"

harvested_sp = group_info %>% filter(Harvested == "Harvested")
### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. ASP"

harvest = asp_df %>% filter(Catch > 0)
#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = harvest)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. Catch"

#### Analyses
analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = harvest)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)


## SEDAR Species Only ----
type = "SEDAR Species"

### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. ASP"

fed_specs = group_info %>% filter(SEDAR == "SEDAR") #Subset dataframe here
#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = fed_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. Catch"

#### Analyses
analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = fed_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

## Resident Species Only ----
type = "Resident Species"

### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. ASP"

resident_specs = group_info %>% filter(Residency == "Resident") #Subset dataframe here
#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = resident_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. ASP ----
scenario = "Landings and Discards - Avg. Catch"

#### Analyses
analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = resident_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

## Landings + Dead Discards ----

#Add bycatch to the landings (Assume landings/bycatch ratio is equal throughout simulation)
reduced_df_landings_only <- reduced_df %>%
  left_join(group_info, by = "Group_Name") %>% 
  mutate(Catch = Catch * Landings_Prop)

## All species regardless of harvest ----
type = "All Species"


#Develop MSY models
result = develop_models(reduced_df_landings_only)

models = result$models
asp_df = result$asp_df

#Plot MSYs (Need to run to get msy_values)
msy_values = plot_models(models,asp_df,type,scenario,to_plot=T) #Can turn plotting off by setting to_plot = F

# Groups where the MSY curve did not provide a suitable curve or did not represent the data. Groups with no curve (no fitting model) are already included
poor_fits = c("Algae","Anchovy-silverside-killifish","Cephalopod","Detritus","Infauna","Mobile epifauna","Offshore dolphins","Phytoplankton","Reef omnivores","Sardine-herring-scad","Sessile epifauna","Zooplankton")

### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. ASP"

#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = asp_df)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. Harvest ----
scenario = "Landings Only - Avg. Harvest"

analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = asp_df)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

## Harvested Species Only ----
type = "Harvested Species"

harvested_sp = group_info %>% filter(Harvested == "Harvested")
### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. ASP"

harvest = asp_df %>% filter(Catch > 0)
#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = harvest)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. Catch"

#### Analyses
analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = harvest)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)


## SEDAR Species Only ----
type = "SEDAR Species"

### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. ASP"

fed_specs = group_info %>% filter(SEDAR == "SEDAR") #Subset dataframe here
#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = fed_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. Catch"

#### Analyses
analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = fed_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

## Resident Species Only ----
type = "Resident Species"

### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. ASP"

resident_specs = group_info %>% filter(Residency == "Resident") #Subset dataframe here
#### Analyses
analyses = ecosystem_caps_avg_asp(msy_values,asp_df,poor_fits,type,scenario,keep_df = resident_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

### Landings Only - Avg. ASP ----
scenario = "Landings Only - Avg. Catch"

#### Analyses
analyses = ecosystem_caps_avg_catch(msy_values,asp_df,poor_fits,type,scenario,keep_df = resident_specs)

all_scenario_data = all_scenario_data %>% add_row(Type = type,Scenario = scenario,BMSY = analyses$BMSYCap,MSY = analyses$MSYCap,MSY_BMSY = analyses$MSYCap/analyses$BMSYCap,Prop_MSY = analyses$MSYProp,Prop_BMSY = analyses$BMSYProp)

#Output full table
write.csv(all_scenario_data,"All Scenario Data.csv")
