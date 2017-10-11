# HERLIN R. ESPINOSA G.
# herlin25@GMAIL.com
# SEP-01-2017

import os
import urllib
from openpyxl import Workbook
from datetime import datetime,timedelta

print ("\n*** Ejecutandose Proceso Descarga Informacion Semanal NOAA... ***\n");

StartDate = str(datetime.now() - timedelta(days=7)).split(' ')[0]
EndDate = str(datetime.now() - timedelta(days=1)).split(' ')[0]
DirResult = 'Output\\' + StartDate + ' a ' + EndDate
if not os.path.exists(DirResult): 
	os.makedirs(DirResult)

currURL = 'https://hads.ncep.noaa.gov/nexhads2/servlet/DecodedData?sinceday=7&hsa=nil&state=HN&nesdis_ids=nil&of=1'
response = urllib.urlopen(currURL)
lines = response.readlines()
StationTmp = ''
for line in lines:
    StrData = line.strip()
    ListData = StrData.split('|')
    Station = ListData[0]
    ListDate = ListData[3].split(' ')
    if StationTmp != Station:
        if StationTmp == '':
            Row = 2
            book = Workbook()
            sheet = book.active
            sheet['A1'] = 'NESDIS ID'
            sheet['B1'] = 'NWSLI'
            sheet['C1'] = 'VARIABLE'
            sheet['D1'] = 'DATE'
            sheet['E1'] = 'HOUR'
            sheet['F1'] = 'VALUE'

            if ListData[5] != 'R':
                sheet['A' + str(Row)] = ListData[0]
                sheet['B' + str(Row)] = ListData[1]
                sheet['C' + str(Row)] = ListData[2]
                sheet['D' + str(Row)] = ListDate[0]
                sheet['E' + str(Row)] = ListDate[1]
                sheet['F' + str(Row)] = ListData[4]
                Row += 1
        else:
            book.save(DirResult + "\\" + StationTmp + ".xlsx")
            Row = 2
            book = Workbook()
            sheet = book.active
            sheet['A1'] = 'NESDIS ID'
            sheet['B1'] = 'NWSLI'
            sheet['C1'] = 'VARIABLE'
            sheet['D1'] = 'DATE'
            sheet['E1'] = 'HOUR'
            sheet['F1'] = 'VALUE'

            if ListData[5] != 'R':
                sheet['A' + str(Row)] = ListData[0]
                sheet['B' + str(Row)] = ListData[1]
                sheet['C' + str(Row)] = ListData[2]
                sheet['D' + str(Row)] = ListDate[0]
                sheet['E' + str(Row)] = ListDate[1]
                sheet['F' + str(Row)] = ListData[4]
                Row += 1
        StationTmp = Station
    else:
        if ListData[5] != 'R':
            sheet['A' + str(Row)] = ListData[0]
            sheet['B' + str(Row)] = ListData[1]
            sheet['C' + str(Row)] = ListData[2]
            sheet['D' + str(Row)] = ListDate[0]
            sheet['E' + str(Row)] = ListDate[1]
            sheet['F' + str(Row)] = ListData[4]
            Row += 1
        StationTmp = Station
book.save(DirResult + "\\" + StationTmp + ".xlsx")
print ("\n*** Proceso Finalizado! ***\n");