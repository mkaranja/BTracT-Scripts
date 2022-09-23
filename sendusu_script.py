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


# Download sendusu

# Download sendusu
r1 = requests.get('https://api.ona.io/api/v1/data/313930?page=1&page_size=10000', auth=('seedtracker', 'Seedtracking101'))
r2 = requests.get('https://api.ona.io/api/v1/data/313930?page=2&page_size=10000', auth=('seedtracker', 'Seedtracking101'))
r3 = requests.get('https://api.ona.io/api/v1/data/313930?page=3&page_size=10000', auth=('seedtracker', 'Seedtracking101'))

#r = requests.get('https://api.ona.io/api/v1/data/313930', auth=('seedtracker', 'Seedtracking101'))

sendusu = r1.json()
sendusu2 = r2.json()
sendusu3 = r3.json()

if len(sendusu2) > 1:
    sendusu += sendusu2
    
    if len(sendusu3) > 1:
        sendusu += sendusu3


#with open('sendusu.json', 'w') as outfile:
 #    json.dump(sendusu, outfile)

# Flowering

Flowering = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['FieldActivities']
        df = pd.DataFrame(sendusu_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_flowering = df[df.fieldActivity == 'flowering']
        dt_flowering = df_flowering[['plantSex', 'flowerName', 'floweringID', 'germplasmID', 'flowering_date']]
        if len(dt_flowering) == 0:
            continue
        else:
            dt1 = pd.DataFrame(dt_flowering)
            #print(dt1.columns)
            Flowering = Flowering.append(dt1, ignore_index=True)
            
    except KeyError as e:
            #print(e)
            continue

flowering = Flowering[["floweringID","flowerName","plantSex","flowering_date"]]
flowering.columns = ["FlowerID","Genotype","Plant_Sex","Flowering_Date"]
flowering['Location'] = 'Sendusu'

flowering['Flowering_Date'] = pd.to_datetime(flowering['Flowering_Date'])
flowering.to_csv("/home/mwk66/BTRACT/daily/data/SendusuAllFlowering.csv", index = False)

recent_flowers = flowering[flowering['Flowering_Date'] > (datetime.now()-timedelta(days=7))]
recent_flowers.to_csv("/home/mwk66/BTRACT/daily/data/SendusuFlowering.csv", index = False)

# First Pollination

FPollination = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['FieldActivities']
        df = pd.DataFrame(sendusu_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_fpollination = df[df.fieldActivity == 'firstPollination']
        dt_fpollination = df_fpollination[["crossID","femaleID", "FemaleName","cycleID","maleAccName","maleID","firstpollination_date","getTrialName"]]
            
        if len(dt_fpollination) == 0:
            continue
        else:
            dt1 = pd.DataFrame(dt_fpollination)
            #print(dt1.columns)
            FPollination = FPollination.append(dt1)
    except KeyError as e:
            #print(e)   
            continue

firstPollination = FPollination[["crossID","femaleID", "FemaleName","cycleID","maleAccName","maleID","firstpollination_date","getTrialName"]]
firstPollination.columns = ["Crossnumber", "FemalePlotName", "Mother", "Cycle", "Father","MalePlotName","First_Pollination_Date","TrialName"]
firstPollination = firstPollination.drop_duplicates()

firstPollination = pd.DataFrame(
    firstPollination.groupby(
            ['Crossnumber']
        ).agg(
            {
		"TrialName" : ['first'],
                "FemalePlotName" : ['first'],
                "Mother": ['first'], 
                "Cycle": ['first'],
                "Father": ['first'],
                "MalePlotName": ['first'],
                'First_Pollination_Date': [max]
            }
        )
)

firstPollination.reset_index(inplace=True)
firstPollination.columns = ["Crossnumber","TrialName", "FemalePlotName", "Mother", "Cycle", "Father","MalePlotName","First_Pollination_Date"]

# Crosses per FemalePlot

crosses = firstPollination[['Crossnumber','FemalePlotName']]
crosses.columns = ['Crossnumber','FemalePlotName']

crosses['number_'] = crosses.groupby('FemalePlotName').cumcount()+1
# crosses['level'] = 'Crossnumber'
crosses["level"] = "Crossnumber_" + crosses["number_"].map(str)
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

crosses_df.to_csv("/home/mwk66/BTRACT/daily/data/SendusuCrossesPerFemalePlot.csv")

RPollination = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['FieldActivities']
        df = pd.DataFrame(sendusu_dict)
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
        df_rpollination = df[df.fieldActivity == 'repeatPollination']
        dt_rpollination = df_rpollination[["rptCrossID", "rptpollination_date"]] 
        
        if len(dt_rpollination) == 0:
            continue
        else:
            dt1 = pd.DataFrame(dt_rpollination)
            #print(dt1.columns)
            RPollination = RPollination.append(dt1)
    except KeyError as e:
            #print(e) 
            continue

repeatPollination = RPollination[["rptCrossID", "rptpollination_date"]]
repeatPollination.columns = ["Crossnumber","Repeat_Pollination_Date"]
repeatPollination = repeatPollination.drop_duplicates()
repeatPollinationsDT = pd.read_csv('/home/mwk66/BTRACT/daily/data/SendusuRepeatPollinationsDT.csv')

repeat_pollination = repeatPollination.append(repeatPollinationsDT, ignore_index=True)
repeat_pollination = repeat_pollination.drop_duplicates()
repeat_pollination['Location'] = "Sendusu"
repeat_pollination.pop('.id')
repeat_pollination.to_csv("/home/mwk66/BTRACT/daily/data/SendusuRepeatPollinations.csv", index=False)

number_of_repeats = repeat_pollination.groupby(['Crossnumber']).count()
number_of_repeats.pop('Location')
number_of_repeats.columns = ['Number_of_Repeats']

# Harvesting 

harvestingDT = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['FieldActivities']
        df = pd.DataFrame(sendusu_dict)
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

# harvesting.Crossnumber.fillna(harvesting['id'], inplace=True)
# harvesting.pop('id')
harvesting = harvesting.dropna(subset=['Crossnumber'])
harvesting = harvesting.sort_values(by=['Bunch_Harvest_Date'])
harvesting = harvesting.drop_duplicates(subset=['Crossnumber'])
harvesting.Bunch_Harvest_Date = pd.to_datetime(harvesting.Bunch_Harvest_Date)
harvesting.Bunch_Harvest_Date = pd.to_datetime(harvesting.Bunch_Harvest_Date, errors='ignore', utc=True).dt.date

# Seed extraction
seedExtraction = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['FieldActivities']
        df = pd.DataFrame(sendusu_dict)
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


sendusu2 = pd.DataFrame(sendusu)


# Embryo Rescue

embryoRescue = sendusu2.filter(regex='embryoRescue')
embryoRescue.columns = embryoRescue.columns.str.replace('Laboratory/embryoRescue/' , '') # embryoRescue.columns = [re.sub("Laboratory/embryoRescue/", "", x) for x in embryoRescue.columns]
embryoDT = embryoRescue[['embryorescueID','goodSeeds','embryorescue_date','embryorescue_seeds']]
embryoDT.columns = ['Crossnumber','Good_Seeds','Embryo_Rescue_Date','Number_of_Embryo_Rescued']

embryoDT = embryoDT.dropna(subset=['Crossnumber'])
embryoDT = embryoDT.drop_duplicates()
embryoDT = embryoDT.dropna(subset=['Number_of_Embryo_Rescued'])
embryoDT = embryoDT.sort_values(by=['Embryo_Rescue_Date', 'Number_of_Embryo_Rescued'], ascending=[True,False])
embryoDT = embryoDT.drop_duplicates(subset=['Crossnumber'])

# # Germination
germination = sendusu2.filter(regex='EmbryoGermination')
germination.columns = germination.columns.str.replace('Laboratory/EmbryoGermination/' , '') 
submission = sendusu2.filter(regex='_submission_time')
germination = germination.join(submission)

germinationDT = germination[['embryo_germinationID','germination_date','number_germinating','germinating_embryo', '_submission_time']]
germinationDT.columns = ['Crossnumber', 'Germination_Date','Number_of_Embryo_Germinating','germinating_embryo','Germination_Submission_Date']
germinationDT.Germination_Submission_Date = pd.to_datetime(germinationDT.Germination_Submission_Date)
germinationDT.Germination_Date = pd.to_datetime(germinationDT.Germination_Date)

germinationDT = germinationDT[germinationDT['Crossnumber'].notna()]
germinationDT = germinationDT.reset_index()
germinationDT.pop('index')
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

# +++++ BANANA DATA +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

r0 = pd.merge(firstPollination, number_of_repeats, how='left', on='Crossnumber')
r1 = pd.merge(r0, harvesting, how='left', on='Crossnumber')
r2 = pd.merge(r1, extraction, how='left', on='Crossnumber')
r3 = pd.merge(r2, embryoDT, how='left', on='Crossnumber')
banana = pd.merge(r3, germinationNumber, how='left', on='Crossnumber')
banana['Location'] = 'Sendusu'

#earlier_sendusu_data = pd.read_csv("/home/mwk66/BTRACT/daily/data/earlier_sendusu_data.csv")
#banana1 = pd.concat([banana, earlier_sendusu_data])
banana = banana.drop_duplicates(subset=["Crossnumber"])
banana.to_csv("/home/mwk66/BTRACT/daily/data/SendusuBananaData.csv",index=False)

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gList = germination.germinating_embryo.dropna()
gDF = pd.DataFrame()

for i in range(gList.size):
    d = pd.DataFrame(gList.iloc[i])
    d.columns = ['embryoID', 'n_embryo', 'germination_date_embryo','number_germinating_position'] 
    gDF = gDF.append(d)

gDF['Crossnumber'] = gDF['embryoID'].str.split('_') .str[:2].str.join('_')
gDF = gDF.drop_duplicates(subset=['embryoID'])

gDT = gDF[['Crossnumber', 'embryoID', 'germination_date_embryo']]
gDT = gDT.rename(columns = {'embryoID': 'PlantletID', 'germination_date_embryo': 'Germination_Date'}, inplace = False)
gDT = gDT.reset_index()

germinationDF = pd.merge(germinationDT[['Crossnumber','Germination_Submission_Date']], gDT,on='Crossnumber',how='left')
germinationDF.pop('index')
germinationDF = germinationDF.sort_values(by=['PlantletID', 'Germination_Date'])
germinationDF = germinationDF.drop_duplicates(subset=['PlantletID'])

germinationDF['Location'] = 'Sendusu'
germinationDF.to_csv("/home/mwk66/BTRACT/daily/data/SendusuGerminatingIDs.csv", index=False)

# Sub-culturing
subculturing = sendusu2.filter(regex='Laboratory/subculturing/')
subculturing.columns = subculturing.columns.str.replace('Laboratory/subculturing/' , '') 
subculturing = subculturing.dropna(subset=['copies'])
subculturing = subculturing[['subcultureID','copies','subculture_date']]
subculturing.columns = ["PlantletID", "Copies","Subculture_Date"]
subculturing = subculturing.drop_duplicates()
subculturing['Location'] = 'Sendusu'
subculturing.to_csv("/home/mwk66/BTRACT/daily/data/SendusuSubcultures.csv", index=False)

subculturing.Copies = pd.to_numeric(subculturing.Copies)

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

subCulturing = pd.DataFrame(subculturing.groupby(['PlantletID'])['Copies'].sum())
subCulturing.columns = ['Copies']

# Rooting

rooting = sendusu2.filter(regex='Laboratory/rooting/')
rooting.columns = rooting.columns.str.replace('Laboratory/rooting/' , '') 
rooting = rooting.dropna(subset=['rootingID'])
rootingDT = rooting[['rootingID','rooting_date','number_rooting']]
rootingDT.columns = ["PlantletID", "Date_of_Rooting","Number_Rooting"]
rootingDT = rootingDT.drop_duplicates()
rootingDT.Number_Rooting = pd.to_numeric(rootingDT.Number_Rooting)
rootingDT['Location'] = 'Sendusu'
rootingDT.to_csv("/home/mwk66/BTRACT/daily/data/SendusuRooting.csv", index=False)

rooting2 = pd.DataFrame(
    rootingDT.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_Rooting': [sum],
                'Date_of_Rooting': [max]
            }
        )
)

rooting2.columns = ['Number_Rooting', 'Date_of_Rooting']
rooting2.reset_index(inplace=True)

rootingDF = pd.DataFrame(rootingDT.groupby(['PlantletID'])['Number_Rooting'].sum())
rootingDF.columns = ['Number_Rooting']

# Sending out - weaning 1

weaning1 = sendusu2.filter(regex='Laboratory/weaning1/')
weaning1.columns = weaning1.columns.str.replace('Laboratory/weaning1/' , '') 
weaning1 = weaning1.dropna(subset=['weaning1ID'])

weaning1DT = weaning1[['weaning1ID','weaning1_date','number_sent_out']]
weaning1DT.columns = ["PlantletID","Sending_Out_Date","Number_Sent_Out"]
weaning1DT = weaning1DT.drop_duplicates()
weaning1DT.Number_Sent_Out = pd.to_numeric(weaning1DT.Number_Sent_Out)
weaning1DT['Location'] = 'Sendusu'
weaning1DT.to_csv("/home/mwk66/BTRACT/daily/data/SendusuWeaning1.csv", index=False)

weaning12 = pd.DataFrame(
    weaning1DT.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_Sent_Out': [sum],
                'Sending_Out_Date': [max]
            }
        )
)

weaning12.columns = ['Number_Sent_Out', 'Sending_Out_Date']
weaning12.reset_index(inplace=True)

weaning1DF = pd.DataFrame(weaning1DT.groupby(['PlantletID'])['Number_Sent_Out'].sum())
weaning1DF.columns = ['Number_Sent_Out']

# Nursery

# Weaning 2

weaning2dt = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['Nursery']
        df = pd.DataFrame(sendusu_dict)
        
        for index, col in enumerate(list(df.columns)):
            cols_labels[col] = col.rsplit('/')[-1]
            df = df.rename(columns=cols_labels)
            
        df_weaning2 = df[df.nurseryActivity == 'weaning2']
            
        if len(df_weaning2) == 0:
            continue
        else:
           # dt = pd.DataFrame(df_flowering[['plantSex', 'flowersID', 'floweringID', 'flowering_date']]
            dt1 = pd.DataFrame(df_weaning2)
            weaning2dt = weaning2dt.append(dt1)
    except KeyError as e:
            #print(e)
            continue

weaning2 = weaning2dt[["weaning2ID", "weaning2_date","number_of_weaning2_plantlets"]]
weaning2.columns = ['PlantletID', 'Weaning_2_Date', 'Number']
weaning2 = weaning2.drop_duplicates()
weaning2['Location'] = 'Sendusu'
weaning2.to_csv("/home/mwk66/BTRACT/daily/data/SendusuWeaning2.csv", index=False)

weaning22 = pd.DataFrame(
    weaning2.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number': [sum],
                'Weaning_2_Date': [max]
            }
        )
)

weaning22.columns = ['Weaning_2_Plantlets', 'Weaning_2_Date']
weaning22.reset_index(inplace=True)

weaning2dt = pd.DataFrame(weaning2.groupby(['PlantletID'])['Number'].sum())
weaning2dt.columns = ['Weaning_2_Plantlets']

# Screenhouse

screenhousedt = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['Nursery']
        df = pd.DataFrame(sendusu_dict)
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
else:
    screenhouse = pd.DataFrame(columns = ["PlantletID","Screenhouse_Transfer_Date","Number_in_Screenhouse"])

screenhouse.Number = pd.to_numeric(screenhouse.Number_in_Screenhouse)
screenhouse = screenhouse.drop_duplicates()
screenhouse['Location'] = 'Sendusu'
screenhouse.to_csv("/home/mwk66/BTRACT/daily/data/SendusuScreenhouse.csv", index=False)

screenhouse2 = pd.DataFrame(
    screenhouse.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number_in_Screenhouse': [sum],
                'Screenhouse_Transfer_Date': [max]
            }
        )
)

#screenhouse2.rename(columns={'Number':'Number_in_Screenhouse'}, inplace=True)
screenhouse2.columns = ['Number_in_Screenhouse', 'Screenhouse_Transfer_Date']

screenhouse = pd.DataFrame(screenhouse.groupby(['PlantletID'])['Number_in_Screenhouse'].sum())
screenhouse.columns = ['Number_in_Screenhouse']

# Hardening

hardeningdt = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['Nursery']
        df = pd.DataFrame(sendusu_dict)
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
    hardening = pd.DataFrame(columns = ["PlantletID","Hardening_Date","Number"])
else:    
    hardening = hardeningdt[["hardeningID","hardening_date","number_of_hardening_plantlets"]]
    hardening.columns = ["PlantletID","Hardening_Date","Number"]
    hardening = hardening.dropna(subset=['PlantletID'])  

hardening.Number = pd.to_numeric(hardening.Number)    
hardening = hardening.drop_duplicates()
hardening['Location'] = 'Sendusu'
hardening.to_csv("/home/mwk66/BTRACT/daily/data/SendusuHardening.csv", index=False)

hardening2 = pd.DataFrame(
    hardening.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number': [sum],
                'Hardening_Date': [max]
            }
        )
)

hardening2.columns = ['Number_in_Hardening', 'Hardening_Date']
hardening2.reset_index(inplace=True)

hardening = pd.DataFrame(hardening.groupby(['PlantletID'])['Number'].sum())
hardening.columns = ['Number_in_hardening']

# Openfield

openfielddt = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['Nursery']
        df = pd.DataFrame(sendusu_dict)
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
    openfield = pd.DataFrame(columns = ["PlantletID","Openfield_Transfer_Date","Number"])    
else:
    openfield = openfielddt[["openfieldID","transplanting_date","number_openfield_transferred_plantlets"]]
    openfield.columns = ["PlantletID","Openfield_Transfer_Date","Number"]
    openfield = openfield.dropna(subset=['PlantletID'])
    openfield = openfield.drop_duplicates()

openfield.Number = pd.to_numeric(openfield.Number)
openfield['Location'] = 'Sendusu'
openfield.to_csv("/home/mwk66/BTRACT/daily/data/SendusuOpenfield.csv", index=False)

openfield2 = pd.DataFrame(
    openfield.groupby(
            ['PlantletID']
        ).agg(
            {
                'Number': [sum],
                'Openfield_Transfer_Date': [max]
            }
        )
)

openfield2.columns = ['Number_in_Openfield', 'Openfield_Transfer_Date']
openfield2.reset_index(inplace=True)

openfield = pd.DataFrame(openfield.groupby(['PlantletID'])['Number'].sum())
openfield.columns = ['Number_in_Openfield']


# Merge plantlets 
p0 = pd.merge(germinationDF, subCulturing, how='left', on='PlantletID')
p1 = pd.merge(p0, rootingDF, how='left', on='PlantletID')
p2 = pd.merge(p1, weaning1DF, how='left', on='PlantletID')
p3 = pd.merge(p2, weaning2dt, how='left', on='PlantletID')
p4 = pd.merge(p3, screenhouse, how='left', on='PlantletID')
p5 = pd.merge(p4, hardening, how='left', on='PlantletID')
p6 = pd.merge(p5, openfield, how='left', on='PlantletID')

plantlets = pd.merge(p6, banana[["Crossnumber","Mother", "Father"]], how='left', on='Crossnumber' )
plantlets = plantlets.drop_duplicates()

cols = ['Location', 'PlantletID', 'Crossnumber', 'Mother', 'Father',  'Germination_Submission_Date', 'Germination_Date', 'Copies', 'Number_Rooting', 'Number_Sent_Out','Weaning_2_Plantlets', 'Number_in_Screenhouse', 'Number_in_hardening','Number_in_Openfield']
plantlets = plantlets[cols]

#earlier_sendusu_plantlets = pd.read_csv("/home/mwk66/BTRACT/daily/data/earlier_sendusu_plantlets.csv")
#plantlets1 = pd.concat([plantlets_sendusu, earlier_sendusu_plantlets])
plantlets = plantlets.drop_duplicates(subset=["PlantletID"])

plantlets.to_csv("/home/mwk66/BTRACT/daily/data/SendusuPlantletsData.csv",index=False)

# ------------------------------------------------------------------------------------
## Plantlets
h0 = pd.merge(germinationDF, subculturing2, how='left', on='PlantletID')
h1 = pd.merge(h0, rooting2, how='left', on='PlantletID')
h2 = pd.merge(h1, weaning12, how='left', on='PlantletID')
h3 = pd.merge(h2, weaning22, how='left', on='PlantletID')
h4 = pd.merge(h3, screenhouse2, how='left', on='PlantletID')
h5 = pd.merge(h4, hardening2, how='left', on='PlantletID')
h6 = pd.merge(h5, openfield2, how='left', on='PlantletID')

#sendusu_firstpollination = pd.read_csv("/home/mwk66/BTRACT/daily/data/sendusu_firstpollination.csv")
#plantlets = pd.merge(h6, sendusu_firstpollination, how='left', on='Crossnumber')
plantlets = h6.drop_duplicates()

# cols = ['Location', 'PlantletID', 'Crossnumber', 'Mother', 'Father',  'Germination_Submission_Date', 'Germination_Date', 'Copies', 'Number_Rooting', 'Number_Sent_Out','Weaning_2_Plantlets', 'Number_in_Screenhouse', 'Number_in_hardening','Number_in_Openfield']
# plantlets = plantlets[cols]

plantlets.to_csv("/home/mwk66/BTRACT/daily/data/SendusuPlantlets.csv",index=False)

# Status
status = pd.DataFrame()
cols_labels = dict()
for i in range(len(sendusu)):
    try:
        sendusu_dict = sendusu[i]['FieldActivities']
        df = pd.DataFrame(sendusu_dict)
        
        for index, col in enumerate(list(df.columns)):
             cols_labels[col] = col.rsplit('/')[-1]
             df = df.rename(columns=cols_labels)
        df_status = df[df.fieldActivity == 'status']
        
        if len(df_status) == 0:
            continue
        else:
            dt1 = pd.DataFrame(df_status)
            status = status.append(dt1, ignore_index=True)
            
    except KeyError as e:
            continue

status = status[['plant_status','plant_statusID','plant_status_date', 'get_status_crossID','plant_status_image','plant_status_notes']].head()
unusual = status[status['plant_status'] == 'unusual']
#if len(unusual) > 0:
#  unusual.columns = unusual.columns.str.replace(r"Unusual/", "")
#  unusual = unusual[["plant_unusualLocPlotName","unusual_Date", "unusual_comments","unusual_image"]]
#  unusual.columns =  ['StatusID','Status_Date','Status','Image']
#  unusual = unusual.dropna(subset=['StatusID'])
#else:
#  unusual = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])

disease = status[status['plant_status'] == 'has_disease']
#if len(disease) > 0:
 # disease.columns = disease.columns.str.replace(r"Disease/", "")
 # disease = disease[["plant_diseaseID","disease_Date", "disease_image","disease_comments"]]
 # disease.columns =  ['StatusID','Status_Date','Status','Image']
 # disease = disease.dropna(subset=['StatusID'])
#else:
#  disease = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])

fallen = status[status['plant_status'] == 'fallen']
#if len(fallen0) > 0:
#  fallen0.columns = fallen0.columns.str.replace(r"fallen_plant/", "")
#  fallen1 = fallen0[["fallen_statusID", "fallen_date", "fallen_image", "fallen_comments"]]
#  fallen1.columns =  ['StatusID','Status_Date','Status','Image']
#  fallen2 = fallen0[["fallen_crossMoStatusID", "fallen_date", "fallen_image", "fallen_comments"]]
#  fallen2.columns =  ['StatusID','Status_Date','Status','Image']
#  fallen = fallen1.append(fallen2)
#  fallen = fallen.dropna(subset=['StatusID'])
#else:
#  fallen = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])


destroyed = status[status['plant_status'] == 'destroyed']
#if len(destroyed) > 0:
#  destroyed.columns = destroyed.columns.str.replace(r"Destroyed/", "")
#  destroyed = destroyed[["plant_destroyedID","destroyed_Date", "destroyed_image","destroyed_comments"]]
#  destroyed.columns =  ['StatusID','Status_Date','Status','Image']
#  destroyed = destroyed.dropna(subset=['StatusID'])
#else:
#  destroyed = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])


bunch_stolen = status[status['plant_status'] == 'bunch_stolen']
#if len(bunch_stolen) > 0:
#  bunch_stolen.columns = bunch_stolen.columns.str.replace(r"stolen_bunch/", "")
#  bunch_stolen = bunch_stolen[["stolenBunch_statusID","stolen_date", "stolen_image","stolen_comments"]]
#  bunch_stolen.columns =  ['StatusID','Status_Date','Status','Image']
#  bunch_stolen = bunch_stolen.dropna(subset=['StatusID'])
#else:
#  bunch_stolen = pd.DataFrame(columns = ['StatusID','Status_Date','Status','Image'])

unusual.columns =  ['Status','StatusID','Status_Date','ID','Image', 'Notes']
destroyed.columns =  ['Status','StatusID','Status_Date','ID','Image', 'Notes']
disease.columns =  ['Status','StatusID','Status_Date','ID','Image', 'Notes']
fallen.columns =  ['Status','StatusID','Status_Date','ID','Image', 'Notes']
bunch_stolen.columns = ['Status','ID','Status_Date','StatusID','Image', 'Notes']


status1 = unusual.append(disease)
status1 = status1.append(fallen)
status1 = status1.append(destroyed)
status1 = status1.append(bunch_stolen)
status = status1
 
# screenhouse_status = pd.DataFrame()
# cols_labels = dict()
# for i in range(len(sendusu)):
#     try:
#         sendusu_dict = sendusu[i]['Nursery']
#         df = pd.DataFrame(sendusu_dict)
#         for index, col in enumerate(list(df.columns)):
#             cols_labels[col] = col.rsplit('/')[-1]
#             df = df.rename(columns=cols_labels)
#         df_status = df[df.nurseryActivity == 'status']
#         if len(df_status) == 0:
#             continue
#         else:
#             dt1 = pd.DataFrame(df_status)
#             screenhouse_status = screenhouse_status.append(dt1, ignore_index=True)
#             
#     except KeyError as e:
#             continue
# 
# status2 = screenhouse_status[["screenhouse_statusID", "screenhousestatus_Date", "note_screenhouse_status", "status_image_screenhouse"]]
# status2 = status2.dropna(subset=['screenhouse_statusID'])
# status2 = status2.reset_index()
# status2 = status2.drop_duplicates()
# status2 = status2.dropna(subset=['screenhouse_statusID'])
# status2.pop("index")
# status2.columns = ['StatusID','Status_Date','Notes','Image']
# 
# status = status1.append(status2)
# status = status.drop_duplicates()
status['Location'] = 'Sendusu'

status.to_csv("/home/mwk66/BTRACT/daily/data/SendusuPlantStatus.csv",index=False)

# Contamination

contamination = sendusu2.filter(regex='embryo_contamination')

if contamination.shape[1] >0:
  contamination.columns = contamination.columns.str.replace('Laboratory/embryo_contamination/' , '') 
  contamination_df = contamination[['number_contaminated','lab_econtaminationID','lab_contamination_date']]
  contamination_df = contamination_df[contamination_df['lab_econtaminationID'].notna()]
  
  contamination_df = contamination_df.reset_index()
  contamination_df.pop('index')
  contamination_df.columns = ['contaminated','PlantletID','Contamination_Date']
  contamination_df = contamination_df.drop_duplicates(subset='PlantletID', keep="first")
  contamination_df['Location'] = 'Sendusu'
    
else:
  contamination_df = pd.DataFrame(columns = ['contaminated','PlantletID','Contamination_Date','Location'])  

contamination_df.to_csv("/home/mwk66/BTRACT/daily/data/SendusuContamination.csv", index=False)


# post updated file to ona.io
upload = subprocess.call(["Rscript", '/home/mwk66/BTRACT/daily/sendusu_upload_media_files.R'])
