import pandas as pd 
import os

DATA_PATH = os.path.join('src', '_data', 'data', 'q1')
count = os.path.join(DATA_PATH, 'count.csv')
flexibility = os.path.join(DATA_PATH, 'flexibility-services.csv')

licence_area_data = os.path.join(DATA_PATH, 'DNO_licence_areas.csv')
licence_areas = pd.read_csv(licence_area_data, usecols=['LongName', 'Licence area Flex'])

flex_count = pd.read_csv(flexibility, usecols=['Licence area', 'No of Service Providers'])
flex_count = flex_count.rename(columns= {
                                'Licence area' : 'licence_area',
                                'No of Service Providers': 'count'
                                })

flex_count = flex_count.groupby('licence_area')['count'].sum().reset_index()

flex_count = flex_count.merge(
        right= licence_areas,
        how='outer',
        left_index=True, right_index=True
    )
flex_count = flex_count.drop(columns=['Licence area Flex']).rename(columns={
    'licence_area': 'long_name',
    'LongName': 'licence_area'
})

flex_count.to_csv(os.path.join(DATA_PATH, 'summarised.csv'), index=False)