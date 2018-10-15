# ExportFromTranskribus
**ExportFromTranskribus** aims at providing a simple tool to export data from Transkribus into conform XML TEI files. 

It is developped within the context of the Time Us project. **Time Us** is a history research project funded by the Agence National de la Recherche. Its purpose is to explore budget times and wages among women and men working in the textile industry in France between the late 17th and early 20th centuries. Exploring digital tools, Time Us involves NLP in order to process archival documents.

## Installing
### Linux (Debian)
* Create virtual environment running with Python 3. For example, in *ExportFromTranskribus* directory type the following command in a terminal: `virtualenv .venv -p python3`

> You may be required to install specific packages prior to creating a virtual environment.

* Start virtual environment. For example, from *ExportFromTranskribus* directory, type the following command in a terminal: `source .venv/bin/activate`

* Install dependencies with Pip. With virtual environment activated, from *ExportFromTranskribus* directory, type the following command in a terminal : `pip install -r requirements.txt`

* Download Saxon Home Edition parser (e.g. `SaxonHE9-9-0-1J`) and unzip it: https://sourceforge.net/projects/saxon/files/Saxon-HE/

* Paste Saxon HE jar file (e.g. `saxon9he.jar`) in *main* directory. 

> If using a different version of Saxon, make sure to modify the value of constant variable "SAXON_JAR" in `run.py`!

### Mac OS

...

## Configuration 
`main/config.py` helps configuring the script. Prior to running `main/run.py`, you need to input the following information:

- *username* and *password* for authentification on Transkribus;
- *collections* and *status* to define which data you aim at exporting from Transkribus.


## Customization of Page2tei
`page2tei_TU.xsl` is the default transformation scenario from PAGE to TEI standard. This file can be edited to match your own needs. 

> If renaming the file, make sure to modify the value of constant variable PAGE2TEI in `run.py`!

## Running
With virtual environment activated, from *ExportFromTranskribus* directory, type the following command in a terminal: `python3 main/run.py`

The script will create files in `main/temp/` directory.
