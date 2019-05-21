# Automatic High Frequency Oscillation Detection (AHFOD) 
**This code is still in development and as such welcomes suggestions and makes no promises.**
---
This code is intended to be used for the detection of High Frequency Oscillations (HFO) in the following data:
* Electroencephalogram EEG (Untested)
* Electrocorticography ECog (Tested)
* intra-cranial Electroencephalogram iEEG (Tested)

## Introduction
### HFO working definition
HFO are recognized as biomarkers for epileptogenic brain tissue. HFOs are generally viewed as spontaneous EEG patterns in the frequency range between 80 to 500 Hz that consist of at least four oscillations that clearly stand out of the background activity. [HFO Review](https://doi.org/10.1016/j.clinph.2019.01.016)


### Uses of HFO
Interictal HFOs have proven more specific in localizing the seizure onset zone (SOZ) than spikes and have presented a good association with the
post-surgery outcome in epilepsy patients. We thus validated the clinical relevance of the HFO area in the individual patient with an automated procedure. This is a prerequisite before HFOs can guide surgical treatment in multi-centre studies.


### Research Papers
[Automatic detection of high frequency oscillations during epilepsy surgery predicts seizure outcome.](https://ac.els-cdn.com/S1388245716304394/1-s2.0-S1388245716304394-main.pdf?_tid=524c5f9d-8e07-463d-9b03-0d05e2917bf1&acdnat=1529503610_35920fdba0906e9b65a5cd236ed1407f)

[Prediction of seizure outcome improved by fast ripples detected in low-noise intra-operative corticogram.](https://ac.els-cdn.com/S1388245717301359/1-s2.0-S1388245717301359-main.pdf?_tid=2f9a228f-f80c-410b-af93-7e1fe08cbce1&acdnat=1529503603_b62d690cf4570225d5c39c58c2e06955)

[Human intracranial high frequency oscillations (HFOs) detected by automatic time-frequency analysis]( https://www.ncbi.nlm.nih.gov/pubmed/24722663)


[Automatic detection of high frequency oscillations during epilepsy surgery predicts seizure outcome ](https://www.ncbi.nlm.nih.gov/pubmed/27472542)

[The morphology of high frequency oscillations (HFO) does not improve delineating the epileptogenic zone](https://www.ncbi.nlm.nih.gov/pubmed/26838666)

[Prediction of seizure outcome improved by fast ripples detected in low-noise intra-operative corticogram](https://www.ncbi.nlm.nih.gov/pubmed/24722663)

[Resection of high frequency oscillations predicts seizure outcome in the individual patient](https://doi.org/10.1038/s41598-017-13064-1)

[High frequency oscillations in scalp EEG mirror seizure frequency in the individual patient.]()

[High density ECoG improves the detection of high frequency oscillations that predict seizure outcome.]()


## How the detector works:
### **Input**: 
The parameters are read from a pre-created "**Para.mat**" file. The .mat-file contains a struct called "**DetPara**". Within the *struct* **DetPara** the following variables can be found. 
See the excell file in the relevant folder.

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

Varaibles |  Description 
------------ | -------------
**filtSig**  	| The signal filtered using filter parameters specified in 
filtSignal   	| Filtered signal.
Envelope     	| Envelope of the signal w.r.t the filtered signal.
**baseline**:	| The filtered signal is searched for intervals of high entropy.
maxNoisemuV     | filtered signal dependent threshold for selecting IndBaseline.
baselineThr     | A values used in event selection based on baseline(envelope).
FiltbaselineThr | A values used in event selection based on baseline(filtered signal).
IndBaseline     | Indeces of the the signal that are taken for baseline calculation.
HiEntropyIntv   | Indexes of high entropy.  
**Events**:     | Collects information on events of interest detected.
EventNumber     | Number of events detected per channel as entries (Cell containing integers).
Markings.start  | Start-index of events.
Markings.end    | End-index of events.
Markings.len    | Length in samples of events.
EventProp       | Cell of tables containing properties of the events detected per channel.
Rates 			| EventNumber devided by duration of signal in minutes.

### **Process:**
The detector is based on thresholding the signal for various power, morphology and energy properties.

1. **Stage 0:** Loading parameters, data and checking for specification inconsistencies.
	1. In this step all the pre-set parameters are centralized and loaded.
	2. The data is loaded and and meta-data parameters are computed.
	3. Several consistencies between parameters and data checked. 
2. **Stage 1:** Band-filter data and compute envelope.
	1. Here all channels are band filtered using a FIR filter with Frequency band and filter parameters specified in parameters.
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
In order to make this more manageable, all parameters are centralized. In the folder **PresetParameters** there is a script **DetectorParameterMaker.m** in it all the pre-set parameters are specified. There is also a file **FIR_2KHz.mat** which contains coefficient of a designed filter. To make you own parameter file just alter the values in the script **DetectorParameterMaker.m** and run the script. To use you own filter coefficients you will have to add this either manually or add a file that you read as **FIR_2KHz.mat** is read.

Alternatively if the constant creation of a parameter.mat file is too much. Then one can also manually alter the parameters in a pre-existing .mat file. This is done via the usual MatLab techniques.


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
**FilterSignal.m** is used to obtain the filtered signal aswell as the envelope. It has the following sub-functions:
1. **filterSignal**: Zero-phase forward and reverse digital IIR filtering, Coefficients set in the parameters. None recursive.
2. **getSignalEnvelope**: obtain the envelope of filtered signal.

### Finding Baseline
```
Baseline.m
├── setBaselineMaxNoisemuV
├── getBaseline
│   ├── getWholeIndHighEntr
│   │   ├── getSignalSeg
│   │   ├── getStockwellData
│   │   │    └── Transform.StockwellTransform
│   │   ├── calcEntropy
│   │   ├── getIndAboveEntrThr
│   │   ├── trimIndBorder
│   │   ├── getIndBrake
│   │   └── getIndHighEntr
│   └── getChannelBaseline
└── setBaslineThreshold
```
**Baseline.m** is used to obtain the baseline of the signal. This function proceeds as follows:
1. **setBaselineMaxNoisemuV**: returns a noise threshold as either a preset value or as a standard deviation of the signal.
2. **getBaseline** &larr; *getWholeIndHighEntr* : finds intervals of high entropy in the signal.
	* **getSignalSeg** : selects a segment of the signal as specified beforhand.
	* **getStockwellData** &larr; Transform.StockwellTransform: see transforms section.
	* **calcEntropy**: standard informational calculation of entropy	
	* **getIndAboveEntrThr**: Thresholding to select intervals of high entropy
	* **trimIndBorder**: Corrective processing needed for the Stockwell transform.
	* **getIndBrake**: Returns indeces in the signal
	* **getIndHighEntr**: collects the indeces
	* **getChannelBaseline** : sets the computed values in the class.
3. **setBaslineThreshold**: Calculate a threshold from the baseline and the entropy for use in event detection

entropy should be lower during oscilations presence of a pattern.
### Finding Events of interest
```
EventsOfInteres
├── findEvents
│   └── findChannelEvents
│       ├──shiftEvelope
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
