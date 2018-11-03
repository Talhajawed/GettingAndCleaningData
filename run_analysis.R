library(dplyr)
library(readr)

# Function that reads the training data from the folder "./UCI HAR Dataset/train". Main data
# comes from file X_train.txt, with added columns for subjectID (from subject_train.txt)
# and activityID (from Y_train.txt). 
readTrainingData <- function() {
  trainingDataFolder <- file.path(".", "UCI HAR Dataset", "train")
  trainingData <- read_table(file.path(trainingDataFolder, "X_train.txt"), col_names = FALSE, col_types = cols())
  trainingLabels <- read_table(file.path(trainingDataFolder, "Y_train.txt"), col_names = c("activityID"), col_types = cols())
  trainingSubjects <- read_table(file.path(trainingDataFolder, "subject_train.txt"), col_names = c("subjectID"), col_types = cols())
  trainingData %>% 
    mutate(subjectID = trainingSubjects$subjectID, activityID = trainingLabels$activityID)   
}

# Function that reads the test data from the folder "./UCI HAR Dataset/test". Main data
# comes from file X_test.txt, with added columns for subjectID (from subject_test.txt)
# and activityID (from Y_test.txt). 
readTestData <- function() {
  testDataFolder <- file.path(".", "UCI HAR Dataset", "test")
  testData <- read_table(file.path(testDataFolder, "X_test.txt"), col_names = FALSE, col_types = cols())
  testLabels <- read_table(file.path(testDataFolder, "Y_test.txt"), col_names = c("activityID"), col_types = cols())
  testSubjects <- read_table(file.path(testDataFolder, "subject_test.txt"), col_names = c("subjectID"), col_types = cols())
  testData %>% 
    mutate(subjectID = testSubjects$subjectID, activityID = testLabels$activityID)
}

# Given two datasets, creates a third one with the rows of both
mergeDataSets <- function(dataSet1, dataSet2) {
  rbind(dataSet1, dataSet2)
}

# Given a dataset with features and a vector of feature names, returns
# a new dataset with only the features that contain mean and standard deviation
# measurements
extractMeanAndStandardDeviationMesurements <- function(data, featureNames) {
  select(data, subjectID, activityID, grep("mean\\.|std\\.", featureNames))
}

# Given a dataset with measurements for activities, joins it with a dataset
# that contains activity labels (read from file "./UCI HAR Dataset/activity_labels.txt")
applyDescriptiveNamesToActivities <- function(data) {
  activityLabels <- read_table(file.path(".", "UCI HAR Dataset", "activity_labels.txt"), col_names = c("activityID", "activity"), col_types = cols())
  inner_join(data, activityLabels, by = "activityID")
}

# Given a dataset with measurements and a vector of feature names, returns a
# new dataset with descriptive names for the measurements. Names have the 
# following pattern: 
#         <signal_domain>_<signal_type>_<measurement_type>_<axis_of_measurement>
# where
#   <singal_domain> = frequencyDomain or timeDomain
#   <signal_type> = bodyAcceleration or gravityAcceleration or bodyAccelerationJerk
#                   or bodyAngularVelocit or bodyAngularVelocityJerk 
#                   or bodyAccelerationMagnitude or bodyAccelerationJerkMagnitude
#                   or gravityAccelerationMagnitude or bodyAngularVelocityMagnitude
#                   or bodyAngularVelocityJerkMagnitude
#   <measurement_type> = mean or standardDeviation
#   <axis_of_measurement> = X, Y, Z or empy
labelDataWithDescriptiveNames <- function(data, featureNames) {
  rename_at(data, vars(-subjectID, -activityID, -activity), ~ grep("mean\\.|std\\.", featureNames, value = TRUE)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(?:^f)(.*)", "frequencyDomain_\\1", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(?:^t)(.*)", "timeDomain_\\1", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:mean)(.*)", "\\1_mean\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:std)(.*)", "\\1_standardDeviaton\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:BodyBody)(.*)", "\\1body\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:Body)(.*)", "\\1body\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:Gravity)(.*)", "\\1gravity\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:Acc)(.*)", "\\1Acceleration\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:Gyro)(.*)", "\\1AngularVelocity\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)(?:Mag)(.*)", "\\1Magnitude\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("([^\\.]*)(?:\\.)([^\\.]*)", "\\1\\2", .)) %>%
    rename_at(vars(-subjectID, -activityID, -activity), ~ gsub("(.*)([XYZ])(.*)", "\\1_\\2Axis\\3", .)) %>%
    mutate(activityID = NULL)
}

# Given a dataset of measurements, calculates another one with the average of
# each measurement group by activity and subject
calculateAverageByActivityAndSubject <- function(data) {
  group_by(data, activity, subjectID) %>%
    summarise_all(funs(mean)) %>%
    rename_at(vars(-subjectID, -activity), ~ paste("averageOf", ., sep = "_"))
}

# Reads the names of features from the file "./UCI HAR Dataset/features.txt"
readFeatureNames <- function() {
  features <- read_table2(file.path(".", "UCI HAR Dataset", "features.txt"), col_names = c("featureID", "feature"), col_types = cols())
  make.names(features$feature, unique = TRUE)
}

featureNames <- readFeatureNames()

finalDataSet <- mergeDataSets(readTrainingData(), readTestData()) %>%
  extractMeanAndStandardDeviationMesurements(featureNames) %>%
  applyDescriptiveNamesToActivities %>%
  labelDataWithDescriptiveNames(featureNames) %>%
  calculateAverageByActivityAndSubject

write.table(finalDataSet, file = file.path(".", "averageByActivityAndSubject.txt"), row.names = FALSE)