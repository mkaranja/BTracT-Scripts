
#! /usr/bin/python3.7
# coding: utf-8

import sys
import json
import requests
import ast
import re
import os
from datetime import date, datetime, timedelta
import pandas as pd
from pandas.io.json import json_normalize
from functools import reduce
import numpy as np

# Download data

kawanda = requests.get('https://api.ona.io/api/v1/data/446576?page=1&page_size=10000', auth=('seedtracker', 'Seedtracking101')).json()
kawanda1 = requests.get('https://api.ona.io/api/v1/data/446576?page=2&page_size=10000', auth=('seedtracker', 'Seedtracking101')).json()
kawanda2 = requests.get('https://api.ona.io/api/v1/data/446576?page=3&page_size=10000', auth=('seedtracker', 'Seedtracking101')).json()

if len(kawanda1) > 1:
    kawanda += kawanda1
    
    if len(kawanda2) > 1:
        kawanda += kawanda2


# Flowering

Flowering = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['FieldActivities']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_flowering = df[df.fieldActivity == 'flowering']
        dt_flowering = df_flowering[['plantSex', 'flowerName', 'floweringID', 'germplasmID', 'flowering_date']]
        if len(dt_flowering) == 0:
            continue
        else:
            dt1 = pd.DataFrame(dt_flowering)
            Flowering = Flowering.append(dt1, ignore_index=True)
            
    except KeyError as e:
            continue

flowering = Flowering[["floweringID","flowerName","plantSex","flowering_date"]]
flowering.columns = ["FlowerID","Genotype","Plant_Sex","Flowering_Date"]
flowering['Location'] = 'Kawanda'

flowering['Flowering_Date'] = pd.to_datetime(flowering['Flowering_Date'])
flowering.to_csv("/home/mwk66/BTRACT/daily/data/KawandaAllFlowering.csv", index = False)
recent_flowers = flowering[flowering['Flowering_Date'] > (datetime.now()-timedelta(days=7))]
recent_flowers.to_csv("/home/mwk66/BTRACT/daily/data/KawandaFlowering.csv", index = False)


# First pollination

FPollination = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['FieldActivities']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_fpollination = df[df.fieldActivity == 'firstPollination']
            
        if len(df_fpollination) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_fpollination)
            dt1["id_"] = i 
            FPollination = FPollination.append(dt1)
    except KeyError as e:
            continue

firstPollination1 = FPollination[["crossID","femaleID", "FemaleName","cycleID","maleAccName","maleID","firstpollination_date","getTrialName", "FemalePloidyLevel", "MalePloidyLevel", "number_of_bracts_fp"]]

firstPollination1.columns = ["Crossnumber", "FemalePlotName", "Mother", "Cycle", "Father","MalePlotName","First_Pollination_Date","TrialName", "FemalePloidyLevel", "MalePloidyLevel", "Number_of_bracts1"]
firstPollination1 = firstPollination1.drop_duplicates()
firstPollination1['Number_of_bracts1'] = firstPollination1['Number_of_bracts1'].fillna(0)

firstPollination2 = pd.DataFrame(
    firstPollination1.groupby(
            ['Crossnumber']
        ).agg(
            {
                "TrialName" : ['first'],
                "FemalePlotName" : ['first'],
                "Mother": ['first'], 
                "Cycle": ['first'],
                "Father": ['first'],
                "MalePlotName": ['first'],
                'First_Pollination_Date': [min],
                "FemalePloidyLevel": ['first'],
                "MalePloidyLevel" : ['first'],
                "Number_of_bracts1": [sum]
            }
        )
)
firstPollination2.reset_index(inplace=True)
firstPollination2.columns = ["Crossnumber","TrialName", "FemalePlotName", "Mother", "Cycle", "Father","MalePlotName","First_Pollination_Date", "FemalePloidyLevel", "MalePloidyLevel", "Number_of_bracts1"]
# Crosses for each FemalePlot

crosses = firstPollination1[['Crossnumber','FemalePlotName']]
crosses.columns = ['Crossnumber','FemalePlotName']
crosses['number_'] = crosses.groupby('FemalePlotName').cumcount()+1
#crosses['number_'] = crosses.groupby('FemalePlotName').count()
crosses['level'] = 'Crossnumber'
crosses["level"] = crosses["level"]+ "_" + crosses["number_"].map(str)
crosses = crosses.sort_values('Crossnumber', ascending=False)
crosses['number_crosses'] = crosses['number_']

crosses_number = pd.DataFrame(
    crosses.groupby(
            ['FemalePlotName']
        ).agg(
            {
                'number_crosses': [max]
            }
        )
)

crosses_number = pd.DataFrame(crosses_number)
crosses_number.columns = ['number_crosses']

crosses_dt = crosses.pivot_table(index='FemalePlotName', 
                                 columns='level', 
                                 values='Crossnumber', aggfunc='first')

crosses_dt = pd.DataFrame(crosses_dt)
crosses_df = pd.merge(crosses_dt, crosses_number, how='left', on='FemalePlotName')

crosses_df.to_csv("/home/mwk66/BTRACT/daily/data/KawandaCrossesPerFemalePlot.csv")

# Pollinators
submitted_by = pd.DataFrame(kawanda)[["_submitted_by" ]]
submitted_by['id_'] = submitted_by.index

pollinators = FPollination[["id_","crossID","username_fp","firstpollination_date"]]

pollinators_data = pd.merge(pollinators, submitted_by, on='id_',  how='left')
pollinators_data.to_csv("/home/mwk66/BTRACT/daily/data/KawandaPollinators.csv")

# Repeat Pollintion

RPollination = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['FieldActivities']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_rpollination = df[df.fieldActivity == 'repeatPollination']
        
        if len(df_rpollination) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_rpollination)
            RPollination = RPollination.append(dt1)
    except KeyError as e:
            continue

repeatPollination = RPollination[["rptCrossID", "rptpollination_date", "number_of_bracts_rp"]]
repeatPollination.columns = ["Crossnumber","Repeat_Pollination_Date", "Number_of_bracts2"]
repeatPollination = repeatPollination.drop_duplicates()
repeatPollination['Number_of_bracts2'] = repeatPollination['Number_of_bracts2'].fillna(0)

repeatPollination['Repeat_Pollination_Date'] = pd.to_datetime(repeatPollination['Repeat_Pollination_Date']).dt.date
repeatPollination['Location'] = "Kawanda"
repeatPollination.to_csv("/home/mwk66/BTRACT/daily/data/KawandaRepeatPollinations.csv", index=False)

repeatPollination['Number_of_Repeats'] = 1
number_of_repeats = repeatPollination.groupby(["Crossnumber"]).sum()
# number_of_repeats.head() 

# Harvesting

harvestingDT = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['FieldActivities']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_harvesting = df[df.fieldActivity == 'harvesting']
            
        if len(df_harvesting) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_harvesting)
            harvestingDT = harvestingDT.append(dt1)
    except KeyError as e:
            #print(e) 
            continue

hList = harvestingDT.multiple_harvests.dropna()
hDT = pd.DataFrame()

for i in range(hList.size):
    d = pd.DataFrame(hList.iloc[i])
    hDT = hDT.append(d)

hDT.columns = hDT.columns.str.replace('FieldActivities/harvesting/multiple_harvests/' , '')     

harvesting = hDT[['harvest/harvestID', 'harvesting_date_grab']]
harvesting.columns = ['Crossnumber','Bunch_Harvest_Date']

harvesting = pd.DataFrame(
    harvesting.groupby(
            ['Crossnumber']
        ).agg(
            {
                'Bunch_Harvest_Date': [min]
            }
        )
)

harvesting.reset_index(inplace=True)
harvesting.columns = ['Crossnumber','Bunch_Harvest_Date']
harvesting.Bunch_Harvest_Date = pd.to_datetime(harvesting.Bunch_Harvest_Date)
harvesting.Bunch_Harvest_Date = pd.to_datetime(harvesting.Bunch_Harvest_Date, errors='ignore', utc=True).dt.date

# Seed Extraction 

seedExtraction = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['FieldActivities']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_extraction = df[df.fieldActivity == 'seedExtraction']
            
        if len(df_extraction) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_extraction)
            seedExtraction = seedExtraction.append(dt1)
    except KeyError as e:
            #print(e) 
            continue

extraction = seedExtraction[["extractionID","extraction_date","totalSeedsExtracted"]]
extraction.columns = ["Crossnumber","Seed_Extraction_Date","Total_Seeds"]
extraction = extraction.drop_duplicates()
extraction = extraction.dropna(subset=['Total_Seeds'])
extraction = extraction.sort_values(by=['Seed_Extraction_Date', 'Total_Seeds'], ascending=[True,False])
extraction = extraction.drop_duplicates(subset=['Crossnumber'])


# LABOLATORY

kawanda2 = pd.DataFrame(kawanda)


# Embryo Rescue
embryoRescue = kawanda2.filter(regex='embryoRescue')
embryoRescue.columns = embryoRescue.columns.str.replace('Laboratory/embryoRescue/' , '') # embryoRescue.columns = [re.sub("Laboratory/embryoRescue/", "", x) for x in embryoRescue.columns]

if len(embryoRescue.columns) >0:
    embryoDT = embryoRescue[['embryorescueID','goodSeeds','embryorescue_date','embryorescue_seeds']]
    
else:
    embryoDT = pd.DataFrame(columns = ['embryorescueID','goodSeeds','embryorescue_date','embryorescue_seeds'])

embryoDT.columns = ['Crossnumber','Good_Seeds','Embryo_Rescue_Date','Number_of_Embryo_Rescued']

embryoDT = embryoDT.dropna(subset=['Crossnumber'])
embryoDT = embryoDT.drop_duplicates()
embryoDT = embryoDT[embryoDT['Embryo_Rescue_Date'].notna()]

embryoDT["Number_of_Embryo_Rescued"] = pd.to_numeric(embryoDT["Number_of_Embryo_Rescued"])
embryoDT = embryoDT.sort_values(by=['Embryo_Rescue_Date', 'Number_of_Embryo_Rescued'], ascending=[True,False])
embryoDT = embryoDT.drop_duplicates(subset=['Crossnumber'])


# Germination
germination = kawanda2.filter(regex='EmbryoGermination')
germination.columns = germination.columns.str.replace('Laboratory/EmbryoGermination/' , '') 

if len(germination.columns) >0:
    germination = germination[['embryo_germinationID','germination_date','number_germinating','germinating_embryo', 'username_eg']]
    germination.columns = ['Crossnumber', 'Germination_Date','Number_of_Embryo_Germinating','germinating_embryo', 'Operator']
else:
    germination = pd.DataFrame(columns = ['Crossnumber', 'Germination_Date','Number_of_Embryo_Germinating','germinating_embryo','Germination_Submission_Date', 'Operator'])


#germination.dropna(inplace=True)
germination['id'] = germination.index
submission = kawanda2[['_submission_time']]
submission['id'] = submission.index

if len(germination) >0:
    germination = germination.merge(submission, on = 'id', how='left')
    germination.pop('id')
    germination = germination.rename(columns={'_submission_time': 'Germination_Submission_Date'})

germinationDT = germination
germinationDT.Germination_Submission_Date = pd.to_datetime(germinationDT.Germination_Submission_Date)
germinationDT.Germination_Submission_Date = germinationDT['Germination_Submission_Date'].dt.date
germinationDT.Germination_Date = pd.to_datetime(germinationDT.Germination_Date)

germinationDT = germination[germination['Crossnumber'].notna()]
germinationDT = germinationDT.reset_index()
germinationDT.pop('index')

germinationDT["Number_of_Embryo_Germinating"] = pd.to_numeric(germinationDT["Number_of_Embryo_Germinating"])

germinationNumber = pd.DataFrame(
    germinationDT.groupby(
            ['Crossnumber']
        ).agg(
            {
                'Number_of_Embryo_Germinating': [sum],
                'Germination_Date' : [min]
            }
        )
)

germinationNumber.columns = ['Number_of_Embryo_Germinating','Germination_Date']

# +++++ BANANA DATA +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

r0 = pd.merge(firstPollination2, number_of_repeats, how='left', on='Crossnumber')
r0['Number_of_bracts'] = r0['Number_of_bracts1'] + r0['Number_of_bracts2']
r0.drop(['Number_of_bracts1', 'Number_of_bracts2'], axis=1, inplace=True)

r1 = pd.merge(r0, harvesting, how='left', on='Crossnumber')
r2 = pd.merge(r1, extraction, how='left', on='Crossnumber')
r3 = pd.merge(r2, embryoDT, how='left', on='Crossnumber')
banana = pd.merge(r3, germinationNumber, how='left', on='Crossnumber')
banana['Location'] = 'Kawanda'
banana.to_csv("/home/mwk66/BTRACT/daily/data/KawandaBananaData.csv",index=False)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gList = germination.germinating_embryo.dropna()
gDF = pd.DataFrame()

for i in range(gList.size):
    d = pd.DataFrame(gList.iloc[i])
    d.columns = ['embryoID', 'n_embryo', 'germination_date_embryo','number_germinating_position'] 
    gDF = gDF.append(d)

if len(gDF) >0:
    gDF['Crossnumber'] = gDF['embryoID'].str.split('_') .str[:2].str.join('_')
    gDF = gDF.drop_duplicates(subset=['embryoID'])
    gDT = gDF[['Crossnumber', 'embryoID', 'germination_date_embryo']]
    gDT = gDT.rename(columns = {'embryoID': 'PlantletID', 'germination_date_embryo': 'Germination_Date'}, inplace = False)
    gDT = gDT.reset_index()
else:
    gDT = pd.DataFrame(columns = ['Crossnumber','PlantletID', 'Germination_Date'])

#germinationDF = pd.concat(germinationDT, gDT,axis = 1)
germinationDF = gDT.merge(germinationDT[['Crossnumber', 'Operator']], left_on='Crossnumber', right_on='Crossnumber')

germinationDF = germinationDF[['Crossnumber','PlantletID', 'Germination_Date', 'Operator']]
germinationDF = germinationDF.drop_duplicates()

banana1 = banana[["Location","Crossnumber", "FemalePloidyLevel", "MalePloidyLevel"]]
df_mask=banana1['Location']=='Kawanda'
bananadt = banana1[df_mask]
bananadt.pop('Location')

germinationDF = pd.merge(germinationDF, bananadt, on='Crossnumber',how='left')
                                        
#if len(germinationDF) >0:
 #   germinationDF.pop('index')
    
germinationDF = germinationDF.sort_values(by=['PlantletID', 'Germination_Date'])
germinationDF = germinationDF.drop_duplicates(subset=['PlantletID'])

germinationDF['Location'] = 'Kawanda'
germinationDF.to_csv("/home/mwk66/BTRACT/daily/data/KawandaGerminatingIDs.csv", index=False)

# Subculturing

subculturing = kawanda2.filter(regex='Laboratory/subculturing/')
subculturing.columns = subculturing.columns.str.replace('Laboratory/subculturing/' , '') 

if len(subculturing.columns) >0:
    subculturing = subculturing.dropna(subset=['copies'])
    subculturing = subculturing[['subcultureID','copies','subculture_date']]
    subculturing.columns = ["PlantletID", "Copies","Subculture_Date"]
    subculturing.Subculture_Date = pd.to_datetime(subculturing.Subculture_Date)
    subculturing.Copies = pd.to_numeric(subculturing.Copies)
else:
    subculturing = pd.DataFrame(columns = ["PlantletID", "Copies","Subculture_Date"])


subculturing2 = pd.DataFrame(
    subculturing.groupby(
            ['PlantletID']
        ).agg(
            {
                'Copies': [sum],
                'Subculture_Date': [min]
            }
        )
)
subculturing2.columns = ['Copies', 'Subculture_Date']
subculturing2.reset_index(inplace=True)

if len(subculturing)>0:
    subculturing['Location'] = 'Kawanda'
    subculturing.to_csv("/home/mwk66/BTRACT/daily/data/KawandaSubcultures.csv", index=False)

subCulturing = pd.DataFrame(subculturing.groupby(['PlantletID'])['Copies'].sum())
subCulturing.columns = ['Copies']

# Rooting

rooting = kawanda2.filter(regex='Laboratory/rooting/')
rooting.columns = rooting.columns.str.replace('Laboratory/rooting/' , '') 
rooting = rooting.drop_duplicates()

if len(rooting.columns) >0 :
    rooting = rooting.dropna(subset=['rootingID'])
    rootingDT = rooting[['rootingID','rooting_date','number_rooting']]
    rootingDT.columns = ["PlantletID", "Date_of_Rooting","Number_Rooting"]
    rootingDT.Number_Rooting = pd.to_numeric(rootingDT["Number_Rooting"])
else: 
    rootingDT = pd.DataFrame(columns = ["PlantletID", "Date_of_Rooting","Number_Rooting"])
    

rooting2 = pd.DataFrame(
    rootingDT.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_Rooting': [sum],
                'Date_of_Rooting': [min]
            }
        )
)
rooting2.columns = ['Number_Rooting', 'Date_of_Rooting']
rooting2.reset_index(inplace=True)

if len(rootingDT)>0:
    rootingDT.loc[:,'Location'] = 'Kawanda' #rootingDT['Location'] = 'Kawanda'
    rootingDT.to_csv("/home/mwk66/BTRACT/daily/data/KawandaRooting.csv", index=False)

rootingDF = pd.DataFrame(rootingDT.groupby(['PlantletID'])['Number_Rooting'].sum())
rootingDF.columns = ['Number_Rooting']
rootingDF.reset_index(inplace=True)

# Sending out - weaning 1

weaning1 = kawanda2.filter(regex='Laboratory/weaning1/')
weaning1.columns = weaning1.columns.str.replace('Laboratory/weaning1/' , '') 
weaning1 = weaning1.drop_duplicates()

if len(weaning1.columns) >0 :
    weaning1 = weaning1.dropna(subset=['weaning1ID'])
    weaning1DT = weaning1[['weaning1ID','weaning1_date','number_sent_out']]
    weaning1DT.columns = ["PlantletID","Sending_Out_Date","Number_Sent_Out"]
    weaning1DT["Number_Sent_Out"] = pd.to_numeric(weaning1DT["Number_Sent_Out"])
    weaning1DT = weaning1DT.drop_duplicates()
else:
    weaning1DT = pd.DataFrame(columns = ["PlantletID","Sending_Out_Date","Number_Sent_Out"])
    

weaning12 = pd.DataFrame(
    weaning1DT.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_Sent_Out': [sum],
                'Sending_Out_Date': [min]
            }
        )
)

weaning12.columns = ['Number_Sent_Out', 'Sending_Out_Date']
weaning12.reset_index(inplace=True)

if len(weaning1DT)>0:
    weaning1DT['Location'] = 'Kawanda'
    weaning1DT.to_csv("/home/mwk66/BTRACT/daily/data/KawandaWeaning1.csv", index=False)

weaning1DF = pd.DataFrame(weaning1DT.groupby(['PlantletID'])['Number_Sent_Out'].sum())
weaning1DF.columns = ['Number_Sent_Out']


# Nursery
# Weaning 2

weaning2dt = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['Nursery']
        df = pd.DataFrame(kawanda_dict)
        
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
            
        df_weaning2 = df[df.nurseryActivity == 'weaning2']
            
        if len(df_weaning2) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_weaning2)
            weaning2dt = weaning2dt.append(dt1)
    except KeyError as e:
            continue
            

if len(weaning2dt) >0:   
    weaning2dt = weaning2dt.drop_duplicates()
    weaning2 = weaning2dt[["weaning2ID", "weaning2_date","number_of_weaning2_plantlets"]]
    weaning2.columns = ['PlantletID', 'Weaning_2_Date', 'Weaning_2_Plantlets']
    weaning2 = weaning2.drop_duplicates()
    weaning2.Number = pd.to_numeric(weaning2["Weaning_2_Plantlets"])
    weaning2 = weaning2.drop_duplicates()
else:
    weaning2 = pd.DataFrame(columns = ['PlantletID', 'Weaning_2_Date', 'Weaning_2_Plantlets'])
    
weaning22 = pd.DataFrame(weaning2.groupby(['PlantletID']).agg({'Weaning_2_Plantlets': [sum],'Weaning_2_Date': [min]}))

weaning22.columns = ['Weaning_2_Plantlets', 'Weaning_2_Date']
weaning22.reset_index(inplace=True)

if len(weaning2)>0:
    weaning2['Location'] = 'Kawanda'
    weaning2.to_csv("/home/mwk66/BTRACT/daily/data/KawandaWeaning2.csv", index=False)
    weaning2 = pd.DataFrame(weaning2.groupby(['PlantletID'])['Weaning_2_Plantlets'].sum())
    weaning2.columns = ['Weaning_2_Plantlets']

# Screenhouse

screenhousedt = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['Nursery']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_screenhouse = df[df.nurseryActivity == 'screenhouse']
        
        if len(df_screenhouse) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_screenhouse)
            screenhousedt = screenhousedt.append(dt1)
    except KeyError as e:
            #print(e)
            continue

if len(screenhousedt) > 0:
    screenhouse = screenhousedt[["screenhouseID", "screenhouse_transfer_date", "number_of_screenhouse_plantlets"]]
    screenhouse.columns = ["PlantletID","Screenhouse_Transfer_Date","Number_in_Screenhouse"]
    screenhouse = screenhouse.dropna(subset=['PlantletID'])
    screenhouse = screenhouse.drop_duplicates()
else:
    screenhouse = pd.DataFrame(columns = ["PlantletID","Screenhouse_Transfer_Date","Number_in_Screenhouse"])


screenhouse2 = pd.DataFrame(
    screenhouse.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_in_Screenhouse': [sum],
                'Screenhouse_Transfer_Date': [min]
            }
        )
)
#screenhouse2.rename(columns={'Number':'Number_in_Screenhouse'}, inplace=True)
screenhouse2.columns = ['Number_in_Screenhouse', 'Screenhouse_Transfer_Date']
screenhouse2.reset_index(inplace=True)

if len(screenhouse)>0:   
    screenhouse['Location'] = 'Kawanda'
    screenhouse.to_csv("/home/mwk66/BTRACT/daily/data/KawandaScreenhouse.csv", index=False)
    screenhouse = pd.DataFrame(screenhouse.groupby(['PlantletID'])['Number_in_Screenhouse'].sum())
    #screenhouse.columns = ['Number_in_Screenhouse']

# Hardening

hardeningdt = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['Nursery']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_hardening = df[df.nurseryActivity == 'hardening']
            
        if len(df_hardening) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_hardening)
            hardeningdt = hardeningdt.append(dt1)
    except KeyError as e:
            #print(e)
            continue

if len(hardeningdt) == 0:
    hardening = pd.DataFrame(columns = ["PlantletID","Hardening_Date","Number_in_hardening"])
else:    
    hardening = hardeningdt[["hardeningID","hardening_date","number_of_hardening_plantlets"]]
    hardening.columns = ["PlantletID","Hardening_Date","Number_in_hardening"]
    hardening = hardening.dropna(subset=['PlantletID'])  
    hardening = hardening.drop_duplicates()


hardening2 = pd.DataFrame(
    hardening.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_in_hardening': [sum],
                'Hardening_Date': [min]
            }
        )
)

hardening2.columns = ['Number_in_hardening', 'Hardening_Date']
hardening2.reset_index(inplace=True)

if len(hardening)>0:
    hardening['Location'] = 'Kawanda'
    hardening.to_csv("/home/mwk66/BTRACT/daily/data/KawandaHardening.csv", index=False)
    hardening = pd.DataFrame(hardening.groupby(['PlantletID'])['Number_in_hardening'].sum())
    #hardening.columns = ['Number_in_hardening']

# Openfield

openfielddt = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['Nursery']
        df = pd.DataFrame(kawanda_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_openfield = df[df.nurseryActivity == 'openfield']
            
        if len(df_openfield) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_openfield)
            openfielddt = openfielddt.append(dt1)
    except KeyError as e:
            #print(e)
            continue

if len(openfielddt) == 0:
    openfield = pd.DataFrame(columns = ["PlantletID","Openfield_Transfer_Date","Number_in_Openfield"])    
else:
    openfield = openfielddt[["openfieldID","transplanting_date","number_openfield_transferred_plantlets"]]
    openfield.columns = ["PlantletID","Openfield_Transfer_Date","Number_in_Openfield"]
    openfield = openfield.dropna(subset=['PlantletID'])
    openfield = openfield.drop_duplicates()

openfield2 = pd.DataFrame(
    openfield.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_in_Openfield': [sum],
                'Openfield_Transfer_Date': [min]
            }
        )
)

openfield2.columns = ['Number_in_Openfield', 'Openfield_Transfer_Date']
openfield2.reset_index(inplace=True)

if len(openfield)>0:
    openfield['Location'] = 'Kawanda'
    openfield.to_csv("/home/mwk66/BTRACT/daily/data/KawandaOpenfield.csv", index=False)
    openfield = pd.DataFrame(openfield.groupby(['PlantletID'])['Number_in_Openfield'].sum())
    #openfield.columns = ['Number_in_Openfield']
    

## Plantlets
p0 = pd.merge(germinationDF, subCulturing, how='left', on='PlantletID')
p1 = pd.merge(p0, rootingDF, how='left', on='PlantletID')
p2 = pd.merge(p1, weaning1DF, how='left', on='PlantletID')
p3 = pd.merge(p2, weaning2, how='left', on='PlantletID')
p4 = pd.merge(p3, screenhouse, how='left', on='PlantletID')
p5 = pd.merge(p4, hardening, how='left', on='PlantletID')
p6 = pd.merge(p5, openfield, how='left', on='PlantletID')

plantlets_kawanda = pd.merge(p6, banana[["Crossnumber","Mother", "Father"]], how='left', on='Crossnumber' )
plantlets_kawanda = plantlets_kawanda.drop_duplicates()

cols = ['Location', 'PlantletID', 'Crossnumber', 'Mother', 'Father',   'Germination_Date', 'Copies', 'Number_Rooting', 'Number_Sent_Out','Weaning_2_Plantlets', 'Number_in_Screenhouse', 'Number_in_hardening','Number_in_Openfield']
plantlets_kawanda = plantlets_kawanda[cols]

plantlets_kawanda.to_csv("/home/mwk66/BTRACT/daily/data/KawandaPlantletsData.csv",index=False)

# ------------------------------------------------------------------------------------
## Plantlets
h0 = pd.merge(germinationDF, subculturing2, how='left', on='PlantletID')
h1 = pd.merge(h0, rooting2, how='left', on='PlantletID')
h2 = pd.merge(h1, weaning12, how='left', on='PlantletID')
h3 = pd.merge(h2, weaning22, how='left', on='PlantletID')
h4 = pd.merge(h3, screenhouse2, how='left', on='PlantletID')
h5 = pd.merge(h4, hardening2, how='left', on='PlantletID')
h6 = pd.merge(h5, openfield2, how='left', on='PlantletID')

plantlets = pd.merge(h6, banana[["Crossnumber","Mother", "Father"]], how='left', on='Crossnumber' )
plantlets = plantlets.drop_duplicates()

cols = ['Location', 'PlantletID', 'Crossnumber', 'Mother', 'Father', 'Germination_Date', 'Copies', 'Number_Rooting', 'Number_Sent_Out','Weaning_2_Plantlets', 'Number_in_Screenhouse', 'Number_in_hardening','Number_in_Openfield']
plantlets = plantlets[cols]

plantlets.to_csv("/home/mwk66/BTRACT/daily/data/KawandaPlantlets.csv",index=False)
# ------------------------------------------------------------------------------------
# Status

status = pd.DataFrame()
cols_labels = dict()
for i in range(len(kawanda)):
    try:
        kawanda_dict = kawanda[i]['FieldActivities']
        df = pd.DataFrame(kawanda_dict)
        
        # for index, col in enumerate(list(df.columns)):
        #     cols_labels[col] = col.rsplit('/')[-1]
        #     df = df.rename(columns=cols_labels)
        df_status = df[df['FieldActivities/fieldActivity'] == 'status']
        
        if len(df_status) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_status)
            status = status.append(dt1, ignore_index=True)
            
    except KeyError as e:
            continue

status = status.filter(regex='FieldActivities/plantstatus/', axis=1)
status.columns = status.columns.str.replace(r"FieldActivities/plantstatus/", "")

if status.shape[1] > 0:
    unusual = status[status['plant_status'] == 'unusual']
    if len(unusual) > 0:
        unusual.columns = unusual.columns.str.replace(r"Unusual/", "")
        unusual = unusual[["plant_unusualLocPlotName","unusual_Date", "unusual_comments","unusual_image"]]
        unusual.columns =  ['StatusID','Status_Date','Status','Image']
        unusual = unusual.dropna(subset=['StatusID'])
    else:
        unusual = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])
        disease = status[status['plant_status'] == 'has_disease']
    if len(disease) > 0:
        disease.columns = disease.columns.str.replace(r"Disease/", "")
        disease = disease[["plant_diseaseID","disease_Date", "disease_image","disease_comments"]]
        disease.columns =  ['StatusID','Status_Date','Status','Image']
        disease = disease.dropna(subset=['StatusID'])
    else:
        disease = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])
        fallen0 = status[status['plant_status'] == 'fallen']
    if len(fallen0) > 0:
        fallen0.columns = fallen0.columns.str.replace(r"fallen_plant/", "")
        fallen1 = fallen0[["fallen_statusID", "fallen_date", "fallen_image", "fallen_comments"]]
        fallen1.columns =  ['StatusID','Status_Date','Status','Image']
        fallen2 = fallen0[["fallen_crossMoStatusID", "fallen_date", "fallen_image", "fallen_comments"]]
        fallen2.columns =  ['StatusID','Status_Date','Status','Image']
        fallen = fallen1.append(fallen2)
        fallen = fallen.dropna(subset=['StatusID'])
    else:
        fallen = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])
        destroyed = status[status['plant_status'] == 'destroyed']
    if len(destroyed) > 0:
        destroyed.columns = destroyed.columns.str.replace(r"Destroyed/", "")
        destroyed = destroyed[["plant_destroyedID","destroyed_Date", "destroyed_image","destroyed_comments"]]
        destroyed.columns =  ['StatusID','Status_Date','Status','Image']
        destroyed = destroyed.dropna(subset=['StatusID'])
    else:
        destroyed = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])
        bunch_stolen = status[status['plant_status'] == 'bunch_stolen']
    if len(bunch_stolen) > 0:
        bunch_stolen.columns = bunch_stolen.columns.str.replace(r"stolen_bunch/", "")
        bunch_stolen = bunch_stolen[["stolenBunch_statusID","stolen_date", "stolen_image","stolen_comments"]]
        bunch_stolen.columns =  ['StatusID','Status_Date','Status','Image']
        bunch_stolen = bunch_stolen.dropna(subset=['StatusID'])
    else:
        bunch_stolen = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])
        status1 = unusual.append(disease)
        status1 = status1.append(fallen)
        status1 = status1.append(destroyed)
        status1 = status1.append(bunch_stolen)
        status1['Location'] = 'Kawanda'
else:
    status1 = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])

status1.to_csv("/home/mwk66/BTRACT/daily/data/KawandaPlantStatus.csv",index=False)


contamination = kawanda2.filter(regex='embryo_contamination')

if contamination.shape[1] >0:
    contamination.columns = contamination.columns.str.replace('Laboratory/embryo_contamination/' , '') 
    contamination_df = contamination[['number_contaminated','lab_econtaminationID','lab_contamination_date']]
    contamination_df = contamination_df[contamination_df['lab_econtaminationID'].notna()]
    contamination_df = contamination_df.reset_index()
    contamination_df.pop('index')
    contamination_df.columns = ['contaminated','PlantletID','Contamination_Date']
    contamination_df = contamination_df.drop_duplicates(subset='PlantletID', keep="first")
    contamination_df['Location'] = 'Kawanda'
else:
    contamination_df = pd.DataFrame(columns = ['contaminated','PlantletID','Contamination_Date','Location'])  

contamination_df.to_csv("/home/mwk66/BTRACT/daily/data/KawandaContamination.csv",index=False)


# post updated file to ona.io
upload = subprocess.call(["Rscript", '/home/mwk66/BTRACT/daily/kawanda_upload_media_files.R'])
