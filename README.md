# ExportFromTranskribus
**ExportFromTranskribus** aims at providing a simple tool to export data from Transkribus into conform XML TEI files. 

It is developped within the context of the Time Us project. **Time Us** is a history research project funded by the Agence National de la Recherche. Its purpose is to explore budget time and wages among women and men working in the textile industry in France between the late 16th and early 20th centuries. Exploring digital tools, Time Us involves NLP in order to process archival documents. To create useable data for NLP, 

## Installing
### Linux (Debian)
* Create virtual environment running with Python 3. For example, in *ExportFromTranskribus* directory type following command in terminal: `virtualenv .venv -p python3`

> You may be required to install specific packages prior to creating a virtual environment.

* Start virtual environment. For example, from *ExportFromTranskribus* directory, type the following command in a terminal: `source .venv/bin/activate`

* Install dependencies with Pip. With virtual environment activated, from *ExportFromTranskribus* directory, type the following command in a terminal : `pip install -r requirements.txt`

### Mac OS

...

## Configuration 
`main/config.py` helps configuring the script. Prior to running `main/run.py`, you need to input the following credentials:

- *username* and *password* for authentification on Transkribus;
- *collectionnames* and *status* to define which date you aim at exporting from Transkribus.
 
## Running
With virtual environment activated, from *ExportFromTranskribus* directory, type the following command in a terminal: `python3 main/run.py`

The script will create files in `main/temp/` directory. They will be overwritten by the script on its next running. 