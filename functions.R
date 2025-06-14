rm(list=ls())

## Libraries
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

### Load biomass and catch data from Ecospace directory ----
load_ecospace_data = function(scen){
  biom = read.csv(paste0("./",scen,"/Ecospace_Annual_Average_Biomass.csv"),check.names = F)
  biom_long = biom %>% 
    pivot_longer(cols = c(colnames(biom)[2:ncol(biom)])) %>% 
    rename(Group = name,Biomass = value)
  
  ### Grab names of functional groups
  fgs = names(biom)[2:length(names(biom))]
  
  ### Catch
  catch = read.csv(paste0("./",scen,"/Ecospace_Annual_Average_Catch.csv"),check.names = F)
  catch_long = catch %>% 
    pivot_longer(cols = c(colnames(catch)[2:ncol(catch)])) %>% 
    mutate(Group = str_extract(name, "(?<=\\|).*")) %>% 
    rename(Catch = value)
  
  merged_df = full_join(biom_long, catch_long, 
                        by = c("Year", "Group")) %>%
    select(Year, Group, Biomass, Catch)
  return(merged_df)
}


### Develop models ----

develop_models <- function(df) {
  # Step 1: Summarize biomass and catch per group and year
  summary_df <- df %>%
    group_by(Year, Group_Name) %>%
    summarise(
      Biomass = sum(Biomass, na.rm = TRUE),
      Catch = sum(Catch, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Step 2: Calculate Annual Surplus Production (ASP)
  asp_df <- summary_df %>%
    arrange(Group_Name, Year) %>%
    group_by(Group_Name) %>%
    mutate(
      B_t_minus1 = lag(Biomass),
      ASP = Biomass - B_t_minus1 + Catch
    ) %>%
    filter(!is.na(ASP)) %>%
    ungroup()
  
  # Step 3: Fit models per group
  models <- asp_df %>%
    group_by(Group_Name) %>%
    nest() %>%
    mutate(
      model = map(data, function(df_group) {
        # Try fitting Schaefer model
        schaefer_fit <- tryCatch(
          nls(ASP ~ r * Biomass * (1 - Biomass / K),
              data = df_group,
              start = list(r = 0.5, K = max(df_group$Biomass, na.rm = TRUE)),
              control = nls.control(maxiter = 100)),
          error = function(e) NULL
        )
        
        # Fallback to quadratic lm if nls fails
        if (is.null(schaefer_fit)) {
          lm(ASP ~ Biomass + I(Biomass^2), data = df_group)
        } else {
          schaefer_fit
        }
      }),
      
      model_type = map_chr(model, ~ if (inherits(.x, "nls")) "Schaefer" else "Quadratic"),
      
      coefs = map(model, ~ coef(.x)),
      
      biomass_range = map(coefs, function(cfs) {
        if ("K" %in% names(cfs)) {
          tibble(Biomass = seq(0, cfs[["K"]], length.out = 100))  # Schaefer
        } else {
          # Quadratic: estimate domain from roots if possible
          a <- cfs["I(Biomass^2)"]
          b <- cfs["Biomass"]
          c <- cfs["(Intercept)"]
          disc <- b^2 - 4*a*c
          if (is.na(a) || a == 0 || disc < 0) {
            return(tibble(Biomass = numeric()))
          }
          r1 <- (-b - sqrt(disc)) / (2*a)
          r2 <- (-b + sqrt(disc)) / (2*a)
          tibble(Biomass = seq(min(r1, r2), max(r1, r2), length.out = 100))
        }
      }),
      
      predictions = map2(model, biomass_range, function(m, b_range) {
        if (nrow(b_range) == 0) return(tibble(Biomass = numeric(), ASP = numeric()))
        pred <- tryCatch(predict(m, newdata = b_range), error = function(e) rep(NA_real_, nrow(b_range)))
        tibble(Biomass = b_range$Biomass, ASP = pred)
      }),MSY_point = map(predictions, ~ slice_max(.x, ASP, n = 1))
    )
  
  return(list(models = models, asp_df = asp_df))
}


## Plot ASP models ##
plot_models = function(models,asp_df,type,scenario,to_plot = T){
  predicted_data <- models %>%
    select(Group_Name, predictions) %>%
    unnest(predictions)
  
  msy_values <- models %>%
    select(Group_Name, MSY_point) %>%
    unnest(MSY_point)
  
  if (to_plot == F){
    return(msy_values)
  }
  
  ### ASP average for unestimable curve ----
  
  # === Plot ===
  # Create a list of species names
  species_list <- unique(asp_df$Group_Name)
  
  # Generate plots for each species
  lapply(species_list, function(species) {
    plot <- ggplot() +
      geom_point(data = subset(asp_df, Group_Name == species), aes(x = Biomass * area, y = ASP * area)) +
      geom_line(data = subset(predicted_data, Group_Name == species), aes(x = Biomass * area, y = ASP * area), color = "blue", size = 1) +
      geom_point(data = subset(msy_values, Group_Name == species), aes(x = Biomass * area, y = ASP * area), color = "red", size = 2) +
      labs(title = species, y = "Annual Surplus Production (ASP; metric tons)", x = "Biomass (B_t; metric tons)") +
      theme_classic()
    
    dirname = paste0("output/",type)
    if (!dir.exists(dirname)){
      dir.create(dirname,recursive = T)
    }
    # Export plot individually with species name
    ggsave(filename = paste0(dirname,"/",species, ".png"), plot = plot, width = 6, height = 4, units = "in", dpi = 300)
  })
  return(msy_values)
}

### Calculate Ecosystem Caps using the average ASP for species without a fitting model
ecosystem_caps_avg_asp = function(msy_values,asp_df,poor_fits,type,scenario,keep_df=c()){
  all_msy = msy_values %>% 
    filter(Biomass > 0,Group_Name %in% unique(keep_df$Group_Name)) %>% 
    mutate(BMSYCap = Biomass * area,MSYCap = ASP * area) %>%
    group_by(Group_Name) %>% 
    summarize(BMSYCap = mean(BMSYCap),MSYCap = mean(MSYCap)) %>% 
    filter(!(Group_Name %in% poor_fits)) %>% 
    mutate(Type = "MSY Curve") %>% 
    as.data.frame()
  
  remaining_sp <- asp_df %>%
    filter(!(Group_Name %in% unique(all_msy$Group_Name)),Group_Name %in% unique(keep_df$Group_Name)) %>%
    group_by(Group_Name) %>%
    summarise(
      mean_asp = mean(ASP, na.rm = TRUE),
      MSYCap = mean_asp * area
    ) %>%
    left_join(
      asp_df %>%
        group_by(Group_Name) %>%
        mutate(diff_to_mean = abs(ASP - mean(ASP, na.rm = TRUE))) %>%
        slice_min(diff_to_mean, n = 1,with_ties=F) %>%
        select(Group_Name, BMSYCap = Biomass),
      by = "Group_Name"
    ) %>%
    mutate(Type = "Average",BMSYCap = BMSYCap * area) %>%
    select(Group_Name, BMSYCap, MSYCap, Type)
  
  all_dat = rbind(all_msy,remaining_sp)
  BMSYCap = sum(all_dat$BMSYCap)
  MSYCap = sum(all_dat$MSYCap)
  
  spec_cap = all_dat %>% 
    mutate(MSYProp = MSYCap / sum(MSYCap),BMSYProp = BMSYCap/sum(BMSYCap)) %>% 
    as.data.frame()
  
  dirname = paste0("./spreadsheets/",type,"/",scenario)
  
  if (!dir.exists(dirname)){
    dir.create(dirname,recursive = T)
  }
  write.csv(spec_cap,paste0(dirname,"/Proportions.csv"))
  
  type_cap = all_dat %>% group_by(Type) %>% summarize(MSYCap = sum(MSYCap),BMSYCap = sum(BMSYCap)) %>% mutate(MSYProp = MSYCap/sum(MSYCap),BMSYProp = BMSYCap/sum(BMSYCap))
  
  MSYProp = type_cap %>%
    filter(Type == "MSY Curve") %>%
    pull(MSYProp)
  
  BMSYProp = type_cap %>%
    filter(Type == "MSY Curve") %>%
    pull(BMSYProp)
  
  return(list(BMSYCap = BMSYCap,MSYCap = MSYCap,MSYProp = MSYProp, BMSYProp = BMSYProp))
}

### Calculate Ecosystem Caps using the average catch for species without a fitting model
ecosystem_caps_avg_catch = function(msy_values,asp_df,poor_fits,type,scenario,keep_df=c()){
  all_msy = msy_values %>% 
    filter(Biomass > 0,Group_Name %in% unique(keep_df$Group_Name)) %>% 
    mutate(BMSYCap = Biomass * area,MSYCap = ASP * area) %>%
    group_by(Group_Name) %>% 
    summarize(BMSYCap = mean(BMSYCap),MSYCap = mean(MSYCap)) %>% 
    filter(!(Group_Name %in% poor_fits)) %>% 
    mutate(Type = "MSY Curve") %>% 
    as.data.frame()
  
  remaining_sp <- asp_df %>%
    filter(!(Group_Name %in% unique(all_msy$Group_Name)),Group_Name %in% unique(keep_df$Group_Name)) %>%
    group_by(Group_Name) %>%
    summarise(
      mean_asp = mean(Catch, na.rm = TRUE),
      MSYCap = mean_asp * area
    ) %>%
    left_join(
      asp_df %>%
        group_by(Group_Name) %>%
        mutate(diff_to_mean = abs(Catch - mean(Catch, na.rm = TRUE))) %>%
        slice_min(diff_to_mean, n = 1,with_ties=F) %>%
        select(Group_Name, BMSYCap = Biomass),
      by = "Group_Name"
    ) %>%
    mutate(Type = "Average",BMSYCap = BMSYCap * area) %>%
    select(Group_Name, BMSYCap, MSYCap, Type)
  
  all_dat = rbind(all_msy,remaining_sp)
  BMSYCap = sum(all_dat$BMSYCap)
  MSYCap = sum(all_dat$MSYCap)
  
  spec_cap = all_dat %>% 
    mutate(MSYProp = MSYCap / sum(MSYCap),BMSYProp = BMSYCap/sum(BMSYCap)) %>% 
    as.data.frame()
  
  dirname = paste0("./spreadsheets/",type,"/",scenario)
  
  if (!dir.exists(dirname)){
    dir.create(dirname,recursive = T)
  }
  write.csv(spec_cap,paste0(dirname,"/Proportions.csv"))
  
  type_cap = all_dat %>% group_by(Type) %>% summarize(MSYCap = sum(MSYCap),BMSYCap = sum(BMSYCap)) %>% mutate(MSYProp = MSYCap/sum(MSYCap),BMSYProp = BMSYCap/sum(BMSYCap))
  
  MSYProp = type_cap %>%
    filter(Type == "MSY Curve") %>%
    pull(MSYProp)
  
  BMSYProp = type_cap %>%
    filter(Type == "MSY Curve") %>%
    pull(BMSYProp)
  
  return(list(BMSYCap = BMSYCap,MSYCap = MSYCap,MSYProp = MSYProp, BMSYProp = BMSYProp))
}
