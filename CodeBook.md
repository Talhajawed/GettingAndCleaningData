## Original Data Set

This project uses the data set [Human Activity Recognition Using Smartphones Data Set](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones). 

The data set contains measurements from the accelerometer and gyroscope 3-axial raw signals. These time domains signals were processed using various filters and trasformations, resulting in measurements for body acceleration, gravity acceleration, angular velocity, their respective Jerk signals and also their magnitude. Fast Fourier Transform was applied to ome of these signals, generating measurements in the frequency domain. A set of variables were then estimated from those signals (mean, standard deviation, median absolute deviation, etc...). 

Most of variables in this original data set follow the naming pattern:

```
<domain><typeOfSignal>-<estimatedVariable>()-<axisOfMeasurement><additionInformation>
```
where

* *domain* is either `t` (time domain) or `f` (frequency domain)
* *typeOfSignal* is one of `BodyAcc` (body acceleration), `GravityAcc` (gravity acceleration), `BodyAccJerk` (Jerk signal for body acceleration), `BodyGyro` (angular velocity), `BodyGyroJerk` (Jerk signal for angular velocity), `BodyAccMag` (magnitude for body acceleration), `GravityAccMag` (magnitude for gravity acceleration), `BodyAccJerkMag` (magnitude for Jerk signal body acceleration), `BodyGyroMag` (magnitude for angular velocity), `BodyGyroJerkMag`(magnitude for the Jerk signal for angular velocity)
* *estimatedVariable* is one of `mean` (Mean value), `std` (Standard deviation), `mad` (Median absolute deviation), `max` (Largest value in array), `min` (Smallest value in array), `sma` (Signal magnitude area), `energy` (Energy measure; sum of the squares divided by the number of values), `iqr` (Interquartile range), `entropy` (Signal entropy), `arCoeff` (Autorregresion coefficients with Burg order equal to 4), `correlation` (correlation coefficient between two signals), `maxInds` (index of the frequency component with largest magnitude), `meanFreq` (Weighted average of the frequency components to obtain a mean frequency), `skewness` (skewness of the frequency domain signal ), `kurtosis` (kurtosis of the frequency domain signal ), `bandsEnergy` (Energy of a frequency interval within the 64 bins of the FFT of each window.)
* *axisOfMeasurement* is `X`, `Y`, `Z` or empty (when the measurement does not involve a specific axis)
* *additionalInformation* is any additional information for the estimated variable in question

Examples of variables in the data set that follow this naming parttern are:

* tBodyAcc-mean()-X: mean of the body acceleration in the X axis, in time domain
* tGravityAcc-mad()-Z: median absolute deviation of gravity acceleration in the Z axis, in time domain
* tBodyAccJerk-sma(): Signal magnitude area of the Jerk signal for body acceleration
* fBodyGyro-min()-Y: Smallest value for angular velocity, in frequency domain
* fBodyGyro-bandsEnergy()-33,48: Energy of a frequency interval for angular velocity. Note that there is no axis of measurement and there are additional information relevant to estimated variable

A few variables do not follow this naming pattern and are related to angle between measured vectors.

The data in the original data set is divided in multiple files. For this project, the following files are relevant:

* features.txt: List of all features.
* activity_labels.txt: Links the class labels with their activity name.
* train/X_train.txt: Training set.
* train/y_train.txt: Training labels.
* test/X_test.txt: Test set.
* test/y_test.txt: Test labels.
* train/subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30
* test/subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30

## Processing the original data set

The following steps were performed to proccess the original data set according to the project instructions: Merge the training set and the test set; Extract only the measurements on the mean and standard deviation; Give descriptive activity names; Give descriptive variable names to the data set; Create a second data set with the average of each variable for each activity and each subject.

### Merge training and test data sets

The training data set is read in the following way:

* Read the file train/X_train.txt, with the measurements values
* Read the file train/Y_train.txt, with the activity ID's for the measurements
* Read the file train/subject_train.txt, with the subject ID's for the measurements
* Add the subject ID's and the activity ID's as columns to the data set containing the measurements values

The test data set is read in a similar way:

* Read the file test/X_test.txt, with the measurements values
* Read the file test/teste.txt, with the activity ID's for the measurements
* Read the file test/subject_test.txt, with the subject ID's for the measurements
* Add the subject ID's and the activity ID's as columns to the data set containing the measurements values

Once the two data set are read, another data set is created with the rows of both data sets.

### Extract only the measurements on the mean and standard deviation

The names of the features are read from the file features.txt. Since these names are going to be used as column names, the R function `make.names` is applied to the names, to guarantee that with have valid, unique names.

Using pattern match, only the columns that correspond to the estimated variables `mean` and `std` are left. The columns with the subjects ID's and activities ID's, are also left in the data set, as they will be used later.


### Give descriptive activity names

The activity names are read from the file activity_labels.txt. These names are applied to the data set using the `inner_join` function, from the `dplyr` package. The join is applied by activity ID.

### Give descriptive variable names to the data set

The names of the features are read from the file features.txt. Since these names are going to be used as column names, the R function `make.names` is applied to the names, to guarantee that with have valid, unique names.

Given the feature names, multiple columns in the data set are renamed by using pattern matching. The following substitution are performed in order:

| Pattern | Substituted text | Explanation |
| ------- | ---------------- | ----------- |
| `(?:^f)(.*)` | `frequencyDomain_\\1` | Make signal domain explicit
| `(?:^t)(.*)` | `timeDomain_\\1` | Make signal domain explicit
| `(.*)(?:mean)(.*)` | `\\1_mean\\2` | Leave mean variable
| `(.*)(?:std)(.*)` | `\\1_standardDeviaton\\2` | Explicit variable name
| `(.*)(?:BodyBody)(.*)` | `\\1body\\2` | Remove duplication
| `(.*)(?:Body)(.*)` | `\\1body\\2` | Lowercase word
| `(.*)(?:Gravity)(.*)` | `\\1gravity\\2` | Lowercase word
| `(.*)(?:Acc)(.*)` | `\\1Acceleration\\2` | Make signal type explicit 
| `(.*)(?:Gyro)(.*)` | `\\1AngularVelocity\\2` | Make signal type explicit 
| `(.*)(?:Mag)(.*)` | `\\1Magnitude\\2` | Make signal type explicit 
| `([^\\.]*)(?:\\.)([^\\.]*)` | `\\1\\2` | Remove extra dots
| `(.*)([XYZ])(.*)` | `\\1_\\2Axis\\3` | Make axis of measurement explicit 

Examples of transformed names:

| Original name | Transformed name |
| ------------- | ---------------- |
| tBodyAcc-mean()-X | timeDomain_bodyAcceleration_mean_XAxis |
| fBodyAccMag-mean() | frequencyDomain_bodyAccelerationMagnitude_mean | 

The columns with subject ID's and activity names are preserved. The column with activity ID's is removed.

### Create a second data set with the average of each variable for each activity and each subject

The previously created data set is then grouped by activity name and subject ID using the `dplyr` `group_by` function and the average for each variable is calculated by the function `summarise_all`, also from `dplyr`. In order to make names more explicit, each measurement column name is given the prefix `averageOf_`. 

## Writing the final data set

After proccessing, the final data set is written to a file named `averageByActivityAndSubject.txt`.

The final file can be read with the following R command:

```R
dataSet <- read.table(file.path(".", "averageByActivityAndSubject.txt"), header = TRUE)
```

