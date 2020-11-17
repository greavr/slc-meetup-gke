import os
from flask import Flask, jsonify, render_template
import requests
import sys

# App Config
app = Flask(__name__)

# Get Sample Key Data
def GetData():
    return []

# Get Environment Vars
def GetEnvVars():
    # Get All Environment Variables

    # Return Set
    resultSet = []

    # Get Pod Scope
    for k, v in os.environ.items():
        aResult = {"scope" : "pod", "name" : k, "value" : v}
        resultSet.append(aResult)
    

    return resultSet

def GetMetaData():
    # Get Node MetaData
    baseURL = "http://metadata.google.internal"
    metaDataHeaders = {'Metadata-Flavor' : 'Google'}
    valuesToFind = ["/computeMetadata/v1/project/numeric-project-id","/computeMetadata/v1/project/project-id","/computeMetadata/v1/instance/zone","/computeMetadata/v1/instance/service-accounts/","/computeMetadata/v1/instance/service-accounts/default/","/computeMetadata/v1/instance/service-accounts/default/scopes","/computeMetadata/v1/instance/service-accounts/default/token"]

    resultSet = []

    # Get Pod Scope
    for aValue in valuesToFind:
        try:
            valueFound = requests.get(baseURL + aValue,headers = metaDataHeaders)
            if valueFound.status_code == 200:
                aResult = {"scope" : "pod", "name" : aValue, "value" : valueFound.text}
        except:   
            e = sys.exc_info()[0]
            aResult = {"scope" : "pod", "name" : aValue, "value" : "Error:" + str(e)}
        resultSet.append(aResult)

    return resultSet


@app.route("/")
def Main():
    return render_template('index.html',EnvVars=GetEnvVars(),MetaData=GetMetaData(),BadData=GetData())

if __name__ == "__main__":
    ## Run APP
    app.run(host='0.0.0.0', port=8080)