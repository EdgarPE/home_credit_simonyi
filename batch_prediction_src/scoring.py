
import pickle
import pandas as pd
import pandas_gbq
import datetime
# import some functions we need to shutdown the VM if we are running in Google Cloud
from shutdown import kill_vm
import atexit


# load new data from Cloud Storage
input_data = pd.read_csv('gs://home-credit-simonyi-workshop/input/application_train.subsample.csv')


# load our saved pipeline pickle file.
try:
    with open('trained_pipe.pkl', 'rb') as f:
        pipe = pickle.load(f)

except FileNotFoundError:
    with open('batch_prediction_src/trained_pipe.pkl', 'rb') as f:
            pipe = pickle.load(f)
except:
    print('Model not found.')
    
        

# Define our feature columns
feature_cols = [
    'DAYS_EMPLOYED',
    'DAYS_BIRTH',
    'AMT_INCOME_TOTAL',
    'AMT_CREDIT',
    'CNT_FAM_MEMBERS',
    'AMT_ANNUITY',
    'EXT_SOURCE_1',
    'EXT_SOURCE_2',
    'EXT_SOURCE_3',
    'NAME_TYPE_SUITE', # categorical
    'NAME_INCOME_TYPE', # categorical
]
    
# Create the predictions and add them to the input dataframe.
input_data = input_data.assign(prediction=pipe.predict_proba(input_data[feature_cols])[:,1],
                               time=datetime.datetime.utcnow())

# Create our final result dataframe
out_data = input_data[['SK_ID_CURR', 'prediction','time']]

# Upload it to BigQuery.
bq_table = 'simonyi_ml.prediction_scores'
pandas_gbq.to_gbq(dataframe=out_data,
                  destination_table=bq_table,
                  project_id='norbert-liki-sandbox',   ## CHANGE THIS TO YOUR PROJECT_ID
                  if_exists='append')

print('Success.')

atexit.register(kill_vm)
