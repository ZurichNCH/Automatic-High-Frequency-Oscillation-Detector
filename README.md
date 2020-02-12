
# Automatic High Frequency Oscillation Detection (AHFOD) 
**This code is still in development and as such welcomes suggestions.**
---
This code is intended to be used for the detection of High Frequency Oscillations (HFO) in the following data:
* Electroencephalogram EEG (Untested)
* Electrocorticography ECoG (Tested)
* Intracranial Electroencephalogram iEEG (Tested) 

## Introduction
### HFO working definition
HFO are recognized as biomarkers for epileptogenic brain tissue. HFOs are generally viewed as spontaneous EEG patterns in the frequency range between 80 to 500 Hz that consist of at least four oscillations that clearly stand out of the background activity. [HFO Review](https://doi.org/10.1016/j.clinph.2019.01.016)   


### Uses of HFO
Interictal HFOs have proven more specific in localizing the seizure onset zone (SOZ) than spikes and have presented a good association with the post-surgery outcome in epilepsy patients. We thus validated the clinical relevance of the HFO area in the individual patient with an automated procedure. This is a prerequisite before HFOs can guide surgical treatment in multi-center studies.


### Research Papers

<a id="1">[1]</a> Burnos S., Hilfiker P., Surucu O., Scholkmann F., Krayenbühl N., Grunwald T. Sarnthein J. Human intracranial high frequency oscillations (HFOs) detected by automatic time-frequency analysis. PLoS One 9, e94381,  [doi:10.1371/journal.pone.0094381]( https://www.doi.org/10.1371/journal.pone.0094381)	 (2014). 

<a id="2">[2]</a> Burnos S., Frauscher B., Zelmann R., Haegelen C., Sarnthein J., Gotman J. The morphology of high frequency oscillations (HFO) does not improve delineating the epileptogenic zone. Clin Neurophysiol 127, 2140-2148, [doi:10.1016/j.clinph.2016.01.002]( https://www.doi.org/10.1016/j.clinph.2016.01.002) (2016).


<a id="3">[3]</a> Fedele T., van 't Klooster M., Burnos S., Zweiphenning W., van Klink N., Leijten F., Zijlmans M., Sarnthein J. Automatic detection of high frequency oscillations during epilepsy surgery predicts seizure outcome. Clin Neurophysiol 127, 3066-3074, [doi:10.1016/j.clinph.2016.06.009 ](  https://www.sciencedirect.com/science/article/pii/S1388245716304394?via%3Dihub) (2016).

<a id="4">[4]</a> Fedele T., Burnos S., Boran E., Krayenbühl N., Hilfiker P., Grunwald T. and Sarnthein J. Resection of high frequency oscillations predicts seizure outcome in the individual patient. Sci Rep 7, 13836,  [doi:10.1038/s41598-017-13064-1]( https://www.doi.org/10.1038/s41598-017-13064-1) (2017).

<a id="5">[5]</a> Fedele T., Ramantani G., Burnos S., Hilfiker P., Curio G., Grunwald T., Krayenbühl N., Sarnthein J. Prediction of seizure outcome improved by fast ripples detected in low-noise intraoperative corticogram. Clin Neurophysiol 128, 1220-1226, [doi:10.1016/j.clinph.2017.03.038]( https://www.doi.org/10.1016/j.clinph.2017.03.038) (2017).


<a id="6">[6]</a> Boran E., Ramantani G., Krayenbühl N., Schreiber M., König K., Fedele T. and Sarnthein J. High-density ECoG improves the detection of high frequency oscillations that predict seizure outcome. Clin Neurophysiol 130, 1882-1888, [doi:10.1016/j.clinph.2019.07.008]( https://www.doi.org/10.1016/j.clinph.2019.07.008) (2019).

<a id="7">[7]</a> Boran E., Sarnthein J., Krayenbühl N., Ramantani G. and Fedele T. High-frequency oscillations in scalp EEG mirror seizure frequency in pediatric focal epilepsy. Sci Rep 9, 16560, [doi:10.1038/s41598-019-52700-w]( https://www.doi.org/10.1038/s41598-019-52700-w) (2019).


		








## How the detector works:
### **Input**: 
The parameters are read from a pre-created "**Para.mat**" file. The .mat-file contains a struct called "**DetPara**". Within the *struct* **DetPara** the following variables can be found. 
See the excel file in the relevant folder.

The data file is stored as "**Data.mat**" with the read-variables given below as well as the computed variable below that.
```
%%
DataFileLocation         	 	% file location of the data, usually given in a script.
%% read
sampFreq           = data.fs;       	% Sampling frequency (SCALAR VALUE)
channelNames       = data.lab_bip;  	% Channel names (CELL OF STRINGS) 
dataSetup          = data.Datasetup;	% Electrode dimensions (STRUCT)
signal             = data.x_bip';   	% Bipolar data (channel-by-sample ARRAY)

%% computed
maxIntervalToJoin  = maxIntervalToJoinPARA*sampFreq;
MinHighEntrIntvLen = MinHighEntrIntvLenPARA*sampFreq;
minEventTime       = minEventTimePARA*sampFreq;
sigDurTime         = length(signal)/sampFreq;
nbChannels         = length(channelNames);
```

### **Output**: HFO-Object with the following categories:

Variables |  Description 
------------ | -------------
**filtSig**  	| The signal filtered using filter parameters specified in 
filtSignal   	| Filtered signal.
Envelope     	| Envelope of the signal w.r.t the filtered signal.
**baseline**:	| The filtered signal is searched for intervals of high entropy.
maxNoisemuV     | filtered signal dependent threshold for selecting IndBaseline.
baselineThr     | A value used in the event selection based on the baseline (envelope).
FiltbaselineThr | A value used in the event selection based on the baseline (filtered signal).
IndBaseline     | Indices of the the signal that are taken for the baseline calculation.
HiEntropyIntv   | Indices of high entropy.  
**Events**:     | Collects information on the events of interest detected.
EventNumber     | Number of the events detected per channel as entries (Cell containing integers).
Markings.start  | Start-index of events.
Markings.end    | End-index of events.
Markings.len    | Samples' Length of the events.
EventProp       | Cell of tables containing properties of the events detected per channel.
Rates 			| EventNumber divided by duration of signal in minutes.

### **Process:**
The detector is based on the thresholding of the signal for various power, morphology and energy properties.

1. **Stage 0:** Loading parameters, data and checking for specification inconsistencies.
	1. In this step all the pre-set parameters are centralized and loaded.
	2. The data is loaded and and meta-data parameters are computed.
	3. Several consistencies between parameters and data  are being (or were) checked. 
2. **Stage 1:** Band-filter the data  and compute the envelope.
	1. Here all channels are band filtered using an FIR filter with Frequency band and filter parameters specified in the parameters.
	2. The **upper envelope** of the filtered signal is then computed.
3. **Stage 2:** Find a baseline for the signal on every channel.
	*
4. **Stage 3:** Find events of interest.
	* 
4. **Stage 4:** Post detections statistics.	


# For users: 

## Installation:
The code is pretty much stand alone apart from obviously requiring MatLab. So just **Clone and run**. 

## Walk-through
For a nice overview of the functionality of this code run ***"HFOWalkthrough.m"*** section by section and read the commentary.
## Demos
### Spectrum
For a demonstration of the functionality run the file ***"RunDemoZurichSpec.m"*** located in the +Demo folder.
### Morphology
For a demonstration of the functionality run the file ***"RunDemoZurichMorph.m"*** located in the +Demo folder.

## Making a parameter file.
Finding HFO is sometimes described as an art. This is a lie, there simply is a lot of parameters that must be set in the detection process.
In order to make this more manageable, all of the parameters are centralized. In the folder **PresetParameters** there is a script **DetectorParameterMaker.m** in it all the pre-set parameters are specified. There is also a file **FIR_2KHz.mat** which contains the coefficients of a designed filter. To make you own parameter file just alter the values in the script **DetectorParameterMaker.m** and run the script. To use you own filter coefficients you will have to add this either manually or add a file that you read the same way as **FIR_2KHz.mat**

Alternatively, if the constant creation of a parameter.mat file is too much, one can also manually alter the parameters in a pre-existing .mat file. This is done via the usual MatLab techniques.


# For Developers:

## Folder Structure:


### Core Files
* HFO.m
    1. ParaAndData.m
    2. FilterSignal.m
    3. Baseline.m
    4. EventsOfInterest.m
* CoOccurence.m


## Function description:
### Loading parameters and data
```
ParaAndData.m
├── loadParameters
├── loadData
└── testParameters
```
**ParaAndData.m** is used to load the parameters and data from the specified *file paths*. It has three sub functions:
1. **loadParameters**: Takes as input a file location of a .mat file in the format given in **DetectorParameterMaker.m**.
2. **loadData**: Takes as input a file location of a .mat file in the format given in the above section. 
3. **testParameters**: A test function to see if the parameters specified do not conflict with the data.

### Filtering Signal
```
FilterSignal.m
├── filterSignal
├── getSignalEnvelope
└── getSmoothSignalEnvelope
```
**FilterSignal.m** is used to obtain the filtered signal as well as the envelope. It has the following sub-functions:
1. **filterSignal**: Zero-phase forward and reverse digital IIR filtering, Coefficients set in the parameters. Non recursive.
2. **getSignalEnvelope**: obtain the envelope of filtered signal.

### Finding Baseline
```
Baseline.m
├── setBaselineMaxNoisemuV
├── getBaseline
│   ├── getWholeIndHighEntr
│   │   ├── getSignalSeg
│   │   ├── getStockwellData
│   │   │    └── Transform.StockwellTransform
│   │   ├── calcEntropy
│   │   ├── getIndAboveEntrThr
│   │   ├── trimIndBorder
│   │   ├── getIndBrake
│   │   └── getIndHighEntr
│   └── getChannelBaseline
└── setBaslineThreshold
```
**Baseline.m** is used to obtain the baseline of the signal. This function proceeds as follows:
1. **setBaselineMaxNoisemuV**: returns a noise threshold as either a preset value or as a standard deviation of the signal.
2. **getBaseline** &larr; *getWholeIndHighEntr* : finds intervals of high entropy in the signal.
	* **getSignalSeg** : selects a segment of the signal as specified beforehand.
	* **getStockwellData** &larr; Transform.StockwellTransform: see transforms section.
	* **calcEntropy**: standard informational calculation of entropy	
	* **getIndAboveEntrThr**: Thresholding to select intervals of high entropy
	* **trimIndBorder**: Corrective processing needed for the Stockwell transform.
	* **getIndBrake**: Returns indices in the signal
	* **getIndHighEntr**: collects the indices
	* **getChannelBaseline** : sets the computed values in the class.
3. **setBaslineThreshold**: Calculate a threshold from the baseline and the entropy in order to be used in the event detection

entropy should be lower during oscilations presence of a pattern.
### Finding Events of interest
```
EventsOfInterest
├── findEvents
│   └── findChannelEvents
│       ├──shiftEvelope
```


# Support

## This code has been written originally by:
* Sergey Burnos
* Tommaso Fedele

## It has been greatly re-factored, improved and is maintained by:

Klinik für Neurochirurgie PhD student:

**Andries Steenkamp**

**JohannesAndriesJacobus.Steenkamp@usz.ch**

**johannes.steenkamp@uzh.ch**

assisted by 

Ece Boran

Ece.Boran@usz.ch

Supervised by

Sarnthein Johannes 

Johannes.Sarnthein@usz.ch




