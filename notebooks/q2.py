import pandas as pd 
import os

DATA_PATH = os.path.join('src', '_data', 'data', 'q1')
flexibility = os.path.join(DATA_PATH, 'flexibility-services.csv')

licence_area_data = os.path.join(DATA_PATH, 'DNO_licence_areas.csv')
licence_areas = pd.read_csv(licence_area_data, usecols=['LongName', 'Licence area Flex'])

flex = pd.read_csv(flexibility, usecols=['Licence area', 'Main technology', 'Total Flexibility Capacity']).rename(columns={
    'Licence area': 'licence_area',
    'Main technology': 'technology',
    'Total Flexibility Capacity': 'capacity'
})

flex = flex.groupby(['licence_area', 'technology'])['capacity'].sum().reset_index()
flex.to_csv(os.path.join(DATA_PATH, 'technology.csv'), index=False)

flex = pd.pivot_table(flex, values='capacity', index=['licence_area'],
                       columns=['technology'], aggfunc="sum").round(2).reset_index().rename(columns={
                           'Biofuel - Biogas from anaerobic digestion (excluding landfill & sewage)': 'Biofuel - Biogas',
                           'Stored Energy (all stored energy irrespectve of the original energy source)': 'Stored Energy (all)',
                           'Water (flowing water or head of water)': 'Water', 
                       })

flex = flex.merge(
        right= licence_areas,
        how='outer',
        left_index=True, right_index=True
    ).drop(columns=['Licence area Flex'])


flex.to_csv(os.path.join(DATA_PATH, 'technology.csv'), index=False)

table = flex.fillna(0)
table.to_csv(os.path.join(DATA_PATH, 'table.csv'), index=False)